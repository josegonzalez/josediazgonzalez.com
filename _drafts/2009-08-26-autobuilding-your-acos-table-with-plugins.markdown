---
  title:       "Auto-Building your ACOs table with Plugins"
  date:        2009-08-26 00:00
  description: Snippet of code that can automatically build CakePHP ACL ACOs for plugins
  category:      CakePHP
  tags:
    - acos
    - authorization
    - cakephp
    - plugins
    - book
    - snippet
    - cakephp 1.2
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

I was fed up with the implementation that is on the Cookbook as far as plugin support goes, so I modified the AuthComponent to recognize things such as controllers/Plugin.Controller/action. Worked well enough, except for the fact that this means that my AuthComponent was simply a patch and therefore unlikely to be merged into the core. I'm also doing a lot of work with making plugin usage in your application seamless, so I guess it was high-time the Cookbook's implementation kicked it up a notch. And since I'm currently idling overnight at JFK (long story :P), here is a present from my delirium to you.

I personally have a 'Core' plugin that has a 'DashboardsController' where I place this code, but you can place it in your AppController and run it as you wish:

Controller Class:

```php
/**
 * DashboardsController
 *
 * This controller does some basic dashboard-like functionality for your application
 *
 * @package app.controllers
 * @author Jose Diaz-Gonzalez
 * @version 0.1
 **/

class DashboardsController extends AppController {
/**
 * The name of this controller. Controller names are plural, named after the model they manipulate.
 *
 * @var string
 * @access public
 */
    var $name = 'Dashboards';

/**
 * Array of models this Controller should have direct access to
 *
 * @var array
 * @access public
 */
    var $uses = array();

/**
 * This function should automatically build your ACO tree
 *
 * @return void
 * @access public
 */
    function build_acos() {
        if (Configure::read('debug') != 0) {
            $log = array();

            $aco =& $this->Acl->Aco;
            $root = $aco->node('controllers');
            if (!$root) {
                $aco->create(array('parent_id' => null, 'model' => null, 'alias' => 'controllers'));
                $root = $aco->save();
                $root['Aco']['id'] = $aco->id;
                $log[] = 'Created Aco node for controllers';
            } else {
                $root = $root[0];
            }

            App::import('Core', 'File');
            $Controllers = App::objects('controller');
            $appIndex = array_search('App', $Controllers);
            if ($appIndex !== false ) {
                unset($Controllers[$appIndex]);
            }
            $baseMethods = get_class_methods('Controller');
            $baseMethods[] = 'buildAcl';

            $Plugins = $this->_getPluginControllerNames();
            $Controllers = array_merge($Controllers, $Plugins);

            // look at each controller in app/controllers
            foreach ($Controllers as $ctrlName) {
                $methods = $this->_getClassMethods($this->_getPluginControllerPath($ctrlName));

                // Do all Plugins First
                if ($this->_isPlugin($ctrlName)){
                    $pluginNode = $aco->node('controllers/'.$this->_getPluginName($ctrlName));
                    if (!$pluginNode) {
                        $aco->create(array('parent_id' => $root['Aco']['id'], 'model' => null, 'alias' => $this->_getPluginName($ctrlName)));
                        $pluginNode = $aco->save();
                        $pluginNode['Aco']['id'] = $aco->id;
                        $log[] = 'Created Aco node for ' . $this->_getPluginName($ctrlName) . ' Plugin';
                    }
                }
                // find / make controller node
                $controllerNode = $aco->node('controllers/'.$ctrlName);
                if (!$controllerNode) {
                    if ($this->_isPlugin($ctrlName)){
                        $pluginNode = $aco->node('controllers/' . $this->_getPluginName($ctrlName));
                        $aco->create(array('parent_id' => $pluginNode['0']['Aco']['id'], 'model' => null, 'alias' => $this->_getPluginControllerName($ctrlName)));
                        $controllerNode = $aco->save();
                        $controllerNode['Aco']['id'] = $aco->id;
                        $log[] = 'Created Aco node for ' . $this->_getPluginControllerName($ctrlName) . ' ' . $this->_getPluginName($ctrlName) . ' Plugin Controller';
                    } else {
                        $aco->create(array('parent_id' => $root['Aco']['id'], 'model' => null, 'alias' => $ctrlName));
                        $controllerNode = $aco->save();
                        $controllerNode['Aco']['id'] = $aco->id;
                        $log[] = 'Created Aco node for ' . $ctrlName;
                    }
                } else {
                    $controllerNode = $controllerNode[0];
                }

                //clean the methods. to remove those in Controller and private actions.
                foreach ($methods as $k => $method) {
                    if (strpos($method, '_', 0) === 0) {
                        unset($methods[$k]);
                        continue;
                    }
                    if (in_array($method, $baseMethods)) {
                        unset($methods[$k]);
                        continue;
                    }
                    $methodNode = $aco->node('controllers/'.$ctrlName.'/'.$method);
                    if (!$methodNode) {
                        $aco->create(array('parent_id' => $controllerNode['Aco']['id'], 'model' => null, 'alias' => $method));
                        $methodNode = $aco->save();
                        $log[] = 'Created Aco node for '. $method;
                    }
                }
            }
            if(count($log)>0) {
                debug($log);
            }
        }
    }

/**
 * Returns the methods of a Controller Class
 *
 * @param string $ctrlName controller class name
 * @return array class methods
 * @access public
 */
    function _getClassMethods($ctrlName = null) {
        App::import('Controller', $ctrlName);
        if (strlen(strstr($ctrlName, '.')) > 0) {
            // plugin's controller
            $num = strpos($ctrlName, '.');
            $ctrlName = substr($ctrlName, $num+1);
        }
        $ctrlclass = $ctrlName . 'Controller';
        return get_class_methods($ctrlclass);
    }

/**
 * Checks whether the controller is part of a plugin or not
 *
 * @param string $ctrlName controller class name
 * @return boolean whether in plugin
 * @access public
 */
    function _isPlugin($ctrlName = null) {
        $arr = String::tokenize($ctrlName, '/');
        if (count($arr) > 1) {
            return true;
        } else {
            return false;
        }
    }

/**
 * Returns a dot separated PluginController path
 *
 * @param string $ctrlName controller class name
 * @return string String containing dot separated PluginController path
 * @access public
 */
    function _getPluginControllerPath($ctrlName = null) {
        $arr = String::tokenize($ctrlName, '/');
        if (count($arr) == 2) {
            return $arr[0] . '.' . $arr[1];
        } else {
            return $arr[0];
        }
    }

/**
 * Returns the name of the plugin for the current controller
 *
 * @param string $ctrlName controller class name
 * @return mixed name of plugin if in plugin, false if not part of a plugin
 * @access public
 */
    function _getPluginName($ctrlName = null) {
        $arr = String::tokenize($ctrlName, '/');
        if (count($arr) == 2) {
            return $arr[0];
        } else {
            return false;
        }
    }

/**
 * Returns the name of the controller for the PluginController pair
 *
 * @param string $ctrlName controller class name
 * @return mixed name of controller if in plugin, false if otherwise
 * @access public
 */
    function _getPluginControllerName($ctrlName = null) {
        $arr = String::tokenize($ctrlName, '/');
        if (count($arr) == 2) {
            return $arr[1];
        } else {
            return false;
        }
    }

/**
 * Get the names of the plugin controllers ...
 *
 * This function will get an array of the plugin controller names, and
 * also makes sure the controllers are available for us to get the
 * method names by doing an App::import for each plugin controller.
 *
 * @return array of plugin names.
 *
 */
    function _getPluginControllerNames() {
        App::import('Core', 'File', 'Folder');
        $paths = Configure::getInstance();
        $folder =& new Folder();
        $folder->cd(APP . 'plugins');

        // Get the list of plugins
        $Plugins = $folder->ls();
        $Plugins = $Plugins[0];
        $arr = array();

        // Loop through the plugins
        foreach($Plugins as $pluginName) {
            // Change directory to the plugin
            $didCD = $folder->cd(APP . 'plugins/' . $pluginName);
            // Get a list of the files that have a file name that ends
            // with controller.php
            $files = $folder->findRecursive('.*_controller\.php');

            // Loop through the controllers we found in the plugins directory
            foreach($files as $fileName) {
                // Get the base file name
                $file = basename($fileName);

                // Get the controller name
                $file = Inflector::camelize(substr($file, 0, strlen($file)-strlen('_controller.php')));
                if (!preg_match('/^'. Inflector::humanize($pluginName). 'App/', $file)) {
                    if (!App::import('Controller', $pluginName.'.'.$file)) {
                        debug('Error importing '.$file.' for plugin '.$pluginName);
                    } else {
                        /// Now prepend the Plugin name ...
                        // This is required to allow us to fetch the method names.
                        $arr[] = Inflector::humanize($pluginName) . "/" . $file;
                    }
                }
            }
        }
        return $arr;
    }
}
```
