---
  title:       "Hide Plugin Prefixes in Routed Urls"
  date:        2009-09-03 00:00
  description: Hack on the CakePHP Router to hide the plugin prefix in connected routes
  category:    cakephp
  tags:
    - cakephp
    - routing
    - quicktip
    - cakephp 1.2
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

```php
/**
 * Parses the request URL into controller, action, and parameters.
 *
 * @package       cake
 * @subpackage    cake.cake.libs
 */
class Router extends Object {
    /**
    * Routes for all the Core and Blog Controllers
    */
    function connectPlugins($pluginNames = array(), $pluginControllers = array(), $options = array()){
        $options = array_merge(array('namespace' => null), $options);
        foreach ($pluginNames as $pluginName) {
            if (empty($pluginControllers[$pluginName])) {
                if (($pluginControllers[$pluginName] = Cache::read("{$pluginName}.controllers")) === false) {
                    App::import('Core', 'File', 'Folder');
                    $paths = Configure::getInstance();
                    $folder =& new Folder();
                    $folder->cd(APP . "plugins/{$pluginName}/controllers");
                    $files = $folder->find('.*_controller\.php');

                    foreach($files as $fileName) {
                        // Get the base file name
                        $file = basename($fileName);
                        $pluginControllers[$pluginName][] = substr($file, 0, strlen($file)-strlen('_controller.php'));
                    }
                    Cache::write("{$pluginName}.controllers", $pluginControllers[$pluginName]);
                }
            }
            if ($options['namespace'] !== null) {
                foreach ($pluginControllers[$pluginName] as $ctrlName) {
                    Router::connect("/{$options['namespace']}_{$ctrlName}/:action/*",
                        array('plugin' => $pluginName, 'controller' => $ctrlName));
                    Router::connect("/" . Configure::read('Routing.admin') . "/{$options['namespace']}_{$ctrlName}/:action/*",
                        array('plugin' => $pluginName, 'controller' => $ctrlName, 'prefix' => Configure::read('Routing.admin'), Configure::read('Routing.admin') => true));
                }
            } else {
                foreach ($pluginControllers[$pluginName] as $ctrlName) {
                    Router::connect("/{$ctrlName}/:action/*",
                        array('plugin' => $pluginName, 'controller' => $ctrlName));
                    Router::connect("/" . Configure::read('Routing.admin') . "/{$ctrlName}/:action/*",
                        array('plugin' => $pluginName, 'controller' => $ctrlName, 'prefix' => Configure::read('Routing.admin'), Configure::read('Routing.admin') => true));
                }
            }
        }
    }
}
```
