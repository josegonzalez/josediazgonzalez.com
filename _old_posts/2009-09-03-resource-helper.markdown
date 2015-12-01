---
  title:              "ResourceHelper"
  date:        2009-09-03 00:00
  description: A general purpose helper to support random functionality that need not be in it's own helper. Has BlueprintCSS support, jQuery ASM HABTM, File displaying, jQuery Error displaying and Google Maps support.
  category:    cakephp
  tags:
    - cakephp
    - helpers
    - overload
    - quicktip
    - cakephp 1.2
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

```php
/**
 * ResourceHelper class file.
 *
 * General Helper to support random functionality that need not be in it's own helper
 * Has BlueprintCSS support, jQuert ASM HABTM, File displaying, jQuery Error displaying
 * and Google Maps support
 *
 * @author Jose Diaz-Gonzalez
 * @license    http://www.opensource.org/licenses/mit-license.php The MIT License
 * @link http://josediazgonzalez/code/resourcehelper/
 * @package app
 * @subpackage app.views.helpers
 * @version .2
 */
class ResourceHelper extends AppHelper {
/**
 * Array of helpers in use by the ResourceHelper
 *
 * @var array
 **/
    var $helpers = array('Form', 'Html');
/**
 * Types of images supported by the ResourceHelper::image() function
 *
 * @var array
 */
    var $_imageTypes = array('.jpg', '.jpeg', '.gif', '.bmp', '.png');

/**
 * Boolean containing whether ResourceHelper::habtm() has been invoked on
 * the form or not
 *
 * @var boolean
 */
    var $_habtm = false;

/**
 * The value of the class attribute assigned to the wrapper div for every
 * label in the format elementType => class
 *
 * @var array
 */
    var $_labelClass = array();

/**
 * The value of the class attribute assigned to the wrapper div for most
 * elements
 *
 * @var string
 */
    var $_inputClass = array();

/**
 * The value of the class assigned outside the input element if necessary
 *
 * @var string
 **/
    var $_specialClass = array();

/**
 * Sets up Blueprint for inclusion in the header
 *
 * @param array $options Additional options to be set if the plugin settings need to be configured
 * @return string
 * @access public
 * @author Jose Diaz-Gonzalez
 **/
    function setup($options = array()) {
        $options = array_merge(array('screen' => 'blueprint/screen','print' => 'blueprint/print'), $options);
        $head = $this->Html->css($options['screen'], 'stylesheet', array('media' => 'screen, projection'));
        $head .= $this->Html->css($options['print'], 'stylesheet', array('media' => 'print'));
        return $head;
    }

/**
 * Sets up the IE stylesheet for the header
 *
 * @param array $options Additional options to be set if the plugin settings need to be configured
 * @return string
 * @access public
 * @author Jose Diaz-Gonzalez
 **/
    function ie($options = array()) {
        $options = array_merge(array('ie' => 'blueprint/ie'), $options);
        $head = "<!--[if IE]>";
        $head .= $this->Html->css($options['ie'], 'stylesheet', array('media' => 'screen'));
        $head .= "<![endif]-->";
        return $head;
    }

/**
 * Wrapper for Html Helper that includes a plugin(s) in the header
 *
 * @param string $path This is the path within the blueprint plugins folder to the plugin(s)
 *                         containing the plugin. Do not include "screen.css" or the trailing slash
 * @param array $options Additional options to be set if the plugin settings need to be configured
 * @return string
 * @access public
 * @author Jose Diaz-Gonzalez
 **/
    function plugins($path = NULL, $options = array()) {
        $styles = '';
        if (!empty($path)) {
            $options = array_merge(array('blueprint' => 'blueprint/plugins','file' => 'screen', 'media' => 'screen, projection'), $options);
            if (is_array($path)) {
                foreach ($path as $plugin) {
                    $styles .= $this->Html->css($options['blueprint'] . "//$plugin//" . $options['file'], 'stylesheet', array('media' => $options['media']));
                }
            } else {
                $styles = $this->Html->css($options['blueprint'] . "//$path//" . $options['file'], 'stylesheet', array('media' => $options['media']));
            }
        }
        return $styles;
    }

/**
 * Caches the blueprintCSS markup needed for labels and form elements
 *
 * @param string $label The value assigned to the class attribute of the div wrapper
 * @param string $input
 * @access public
 * @author Dave Mahon
 */
    function configure($elements, $label = '', $input = '', $special = '') {
        if (is_array($elements)) {
            foreach ($elements as $element){
                $this->_labelClass[$element] = $label;
                $this->_inputClass[$element] = $input;
                if (!empty($special)) {
                    $this->_specialClass[$element] = $special;
                }
            }
        } else {
            $this->_labelClass[$elements] = $label;
            $this->_inputClass[$elements] = $input;
            if (!empty($special)) {
                $this->_specialClass[$elements] = $special;
            }
        }
    }

/**
 * Wrapper for FormHelper->input that adds blueprintCSS markup
 *
 * @param string $fieldName This should be "Modelname.fieldname", "Modelname/fieldname" is deprecated
 * @param array $options
 * @param boolean $tagging if true
 * @return string
 * @access public
 * @author Dave Mahon
 */
    function input($fieldName, $options = array(), $tagging = false) {
        if (!isset($options['type'])) {
            $options['type'] = 'text';
        }

        if (!empty($this->_specialClass[$options['type']])) {
            $options = array_merge(array(
                'before' => '<div class="' . $this->_labelClass[$options['type']] . '">',
                'between' => '</div><div class="' . $this->_specialClass[$options['type']] . '"><div class="' . $this->_inputClass[$options['type']] . '">',
                'after' => '</div></div>'
                ), $options);
        } else {
            $options = array_merge(array(
                'before' => '<div class="' . $this->_labelClass[$options['type']] . '">',
                'between' => '</div><div class="' . $this->_inputClass[$options['type']] . '">',
                'after' => '</div>'
                ), $options);
        }
        if ($tagging) {
            App::import('Helper', 'Tagging.Tagging');
            return $this->Tagging->input($fieldName, $options);
        }
        return $this->Form->input($fieldName, $options);
    }

/**
 * Wrapper for FormHelper->end that adds blueprintCSS markup
 *
 * If $options is set a form submit button will be created.
 *
 * @param mixed $options as a string will use $options as the value of button,
 *                         array usage:
 *                             array('label' => 'save'); value="save"
 *                             array('label' => 'save', 'name' => 'Whatever'); value="save" name="Whatever"
 *                             array('name' => 'Whatever'); value="Submit" name="Whatever"
 *                             array('label' => 'save', 'name' => 'Whatever', 'div' => 'good') <div class="good"> value="save" name="Whatever"
 *                             array('label' => 'save', 'name' => 'Whatever', 'div' => array('class' => 'good')); <div class="good"> value="save" name="Whatever"
 *
 * @return string a closing FORM tag optional submit button.
 * @access public
 * @author Dave Mahon
 */
    function end($options = null) {
        if ($options !== null) {
            if (is_string($options)) {
                $options = array('label'=>$options);
            }
            if (isset($options['div'])) {
                $options['div'] = $this->addClass($options['div'], 'clear');
            } else {
                $options['div'] = array('class' => 'clear');
            }
        }
        return $this->Form->end($options);
    }

/**
 * Wrapper for HtmlHelper->div that adds blueprintCSS markup for class clear
 *
 * @param string $fieldName This should be "Modelname.fieldname", "Modelname/fieldname" is deprecated
 * @param string $class CSS class name of the div element.
 * @param string $text String content that will appear inside the div element.
 *                         If null, only a start tag will be printed
 * @param array $attributes Additional HTML attributes of the DIV tag
 * @param boolean $escape If true, $text will be HTML-escaped
 * @return string The formatted DIV element
 * @access public
 * @author Dave Mahon
 */
    function clear($class = null, $text = null, $attributes = array(), $escape = false) {
        if (strlen($class) > 0) {
            $class .= ' clear';
        } else {
            $class = 'clear';
        }
        return $this->Html->div($class, $text, $attributes, $escape);
    }

/**
 * Automatically wraps text(s) with classes/ids
 *
 * @param boolean $wrapAll whether or not to wrap each text with the same class. true by default
 * @param string/array $texts string or array of text that should be wrapped
 * @param string/array $classes string or array of classes to wrap the texts
 * @param string/array $ids string or array of ids to wrap the texts
 * @return void
 * @author Jose Diaz-Gonzalez
 **/
    function span($wrapAll = true, $texts = NULL, $classes = NULL, $ids = null) {
        $finalText = '';
        if (is_array($texts)) {
            if ($wrapAll) {
                foreach ($texts as $text) {
                    $finalText .= "<div";
                    if (isset($ids)) {
                        $finalText .= " id=\"$ids\"";
                    }
                    if (isset($classes)) {
                        $finalText .= " class=\"$classes\"";
                    }
                    $finalText .= ">$text</div>";
                }
            } else {
                $i = 0;
                foreach($texts as $text) {
                    $finalText .= "<div";
                    if (isset($ids)) {
                        $finalText .= " id=\"" . $ids[$i] . "\"";
                    }
                    if (isset($classes)) {
                        $finalText .= " class=\"" . $classes[$i] . "\"";
                    }
                    $finalText .= ">$text</div>";
                }
            }
        } else {
            $finalText .= "<div";
            if (isset($ids)) {
                $finalText .= " id=\"" . $ids[$i] . "\"";
            }
            if (isset($classes)) {
                $finalText .= " class=\"" . $classes[$i] . "\"";
            }
            $finalText .= ">$text</div>";
        }
        return $finalText;
    }

    function submit($title = 'Submit', $options = array()) {
        $defaults = array('type' => 'submit');
        $options = array_merge($defaults, $options);
        if (isset($options['class'])) {
            $options['class'] .= ' positive';
        } else {
            $options['class'] = ' positive';
        }

        $keys = array_keys($options);
        $values = array_values($options);

        $buttonOptions = '';
        for ($i = 0; $i < count($keys); $i++) {
            $buttonOptions .= " " . $keys[$i] . "=\"" . $values[$i] . "\"";
        }

        return "<div class=\"button\"><button{$buttonOptions}>{$title}</button></div>";
    }

    function habtm($field, $options = array()) {
        $defaults = array('jsPath' => 'jquery/asm');
        $options = array_merge($defaults, $options);

        if ($this->_habtm) {
            return $this->Form->input($field);
        } else {
            $this->_habtm = true;
            return $this->Form->input($field) . $this->Html->script($options['jsPath'], false);
        }
    }

    function file($value, $options = array()) {
        if ($this->_isImage($value)) {
            if ($this->_isUrl($value)) {
                $options['url'] = $value;
                return $this->Html->image("{$value}", $options);
            } else {
                return $this->Html->image("/{$value}", $options);
            }
        }
        $link = Router::url("/{$value}", true);
        return $this->Html->link("{$link}", "/{$value}", $options);
    }

    function image($value, $options = array(), $foptions = array()) {
        $defaults = array();
        $options = array_merge($defaults, $options);
        $defoptions = array($path = null, $size = 'medium', 'url' => null);
        $foptions = array_merge($defoptions, $foptions);

        return $this->Html->image("../{$foptions['path']}/thumb/{$foptions['size']}/{$value}", $options);
    }

    function imageLink($value, $options = array()){
        if ($this->_isImage($value)) {
            if ($this->_isUrl($value)) {
                $options['url'] = $value;
                return $this->Html->image("{$value}", $options);
            } else {
                return $this->Html->image("/{$value}", $options);
            }
        }
        return $value;
    }

    function value($value, $options = array()) {
        $defaults = array('div' => true);
        $options = array_merge($defaults, $options);
        if (isset($value) and !empty($value) and ($value !== '')) {
            if ($options['div']){
                return "<div>{$value}</div>";
            }
            return "{$value}<br />";
        }
        return "{$value}";
    }

    function map($api, $options = array()) {
        return
            '<div id="map_container">
                <div id="big_spinner" style="display:none"></div>
                <div id="map"></div>
                <div id="map_tooltip">
                    drag marker to fix location
                </div>
            </div>' . $this->_mapSetup($api, $options);
    }

    function mapInput($value, $options = array()) {
        $defaults = array('onchange' => 'widget.initMap()');
        $options = array_merge($defaults, $options);
        return $this->Form->input($value, $options);
    }

/**
* Prints out a jQuery enhanced list of validation errors
*
* @param array $data Array of all possible errors for all models being validated
* @param integer $type Integer indicating the css id of the error
* @param boolean $flash Boolean indicating whether this is a flash message
* @access public
*/
    function validationErrors($data, $id, $flash = false){
        $errors = $this->_getArray($data);
        if ($errors != array()){
            echo $this->_jqueryList(array_values($errors), $id, $flash);
        }
    }

/**
* Prints out a jQuery enhanced list of validation errors
*
* @param array $data Array of all possible errors
* @param integer $type Integer indicating the css id of the error
* @param boolean $flash Boolean indicating whether this is a flash message
* @return string String of Javascript/HTML containing list of errors
* @access public
*/
    function _jqueryList($data, $type, $flash) {
        $temp = $this->_getList($data, $flash);
        $id = $this->_getType($type);
        if ($flash){
            $output = "<div id=\"". $id ."\" class=\"flash\"style=\"display: none\">Error Message:<br />{$temp}</div>
                <script type=\"text/javascript\">
                    jQuery(document).ready(function() {
                        $ (\".flash\").fadeIn(\"slow\");
                    });
                </script>";
        } else {
            $output = "<div id=\"". $id ."\" class=\"flash\"style=\"display: none\">Reasons for error:<br />{$temp}</div>
                <script type=\"text/javascript\">
                    jQuery(document).ready(function() {
                        $ (\".flash\").fadeIn(\"slow\");
                    });
                </script>";
        }

        return $output;
    }

/**
* Used in conjunction with jQueryList
* Returns the id of the notice
*
* @param integer $data Integer referencing an error type
* @return string String assigned to an error
* @access public
*/
    function _getType($data){
        $output = "";
        switch ($data) {
            case 0:
                $output = "error";
                break;
            case 1:
                $output = "success";
                break;
            case 2:
                $output = "notice";
                break;
            case 3:
                $output = "reasons";
                break;
            default:
                $output = "notice";
                break;
        }
        return $output;
    }

/**
* Returns a list of items, each wrapped in an <li></li>
*
* @param array $data Array of all possible items
* @param boolean $flash Boolean indicating whether this is a flash message
* @return string String containing a <li></li> wrapped list of items
* @access public
*/
    function _getList($data, $flash){
        $output = '';
        if (is_array($data)){
            if($flash){
                $output .= "<li>{$data['0']}</li>";
            } else {
                foreach($data as $item){
                    $output .= "<li>{$item}</li>";
                }
            }
        }
        else {
            $output .= "<li>{$data}</li>";
        }
        return "<ul>".$output."</ul>";
    }

/**
* Returns an Array of items that are nested within some other array
*
* @param array $data Array of items which may be arrays themselves
* @return array Array of items which remove one layer of nesting
* @access public
*/
    function _getArray($data){
        $arrayValues = array_values($data);
        $output = array();
        foreach($arrayValues as $value){
            $output += $value;
        }
        return $output;
    }

    function _endsWith($input = null, $query = null) {
        // Get the length of the end string
        $queryLength = strlen($query);
        // Look at the end of input for the substring the size of query
        $inputEnd = substr($input, strlen($input) - $queryLength);
        // If it matches, it does end with query
        return $inputEnd == $query;
    }

    function _isImage($input) {
        foreach ($this->_imageTypes as $imageType) {
            if ($this->_endsWith($input, $imageType)) {
                return true;
            }
        }
        return false;
    }

    function _mapSetup($api = null, $options = array()) {
        $defaults = array('proxy' => 'map/proxy', 'addresschooser' => 'map/addresschooser', 'display' => 'map/display');
        $options = array_merge($defaults, $options);
        $return = $this->Html->script('http://www.google.com/jsapi?key=' . $api, array('safe' => false));
        $return .= $this->Html->script($options['proxy'], array('safe' => false));
        $return .= $this->Html->script($options['addresschooser'], array('safe' => false));
        $return .= $this->Html->script($options['display'], array('safe' => false));
        return $return;
    }

/**
 * Checks that a value is a valid URL according to http://www.w3.org/Addressing/URL/url-spec.txt
 *
 * The regex checks for the following component parts:
 *     a valid, optional, scheme
 *         a valid ip address OR
 *         a valid domain name as defined by section 2.3.1 of http://www.ietf.org/rfc/rfc1035.txt
 *      with an optional port number
 *    an optional valid path
 *    an optional query string (get parameters)
 *    an optional fragment (anchor tag)
 *
 * @param string $check Value to check
 * @param boolean $strict Require URL to be prefixed by a valid scheme (one of http(s)/ftp(s)/file/news/gopher)
 * @return boolean Success
 * @access public
 */
    function _isUrl($check, $strict = false) {
        $_this =& Validation::getInstance();
        $_this->check = $check;
        $validChars = '([' . preg_quote('!"$&\'()*+,-.@_:;=') . '\/0-9a-z]|(%[0-9a-f]{2}))';
        $_this->regex = '/^(?:(?:https?|ftps?|file|news|gopher):\/\/)' . ife($strict, '', '?') .
            '(?:' . $_this->__pattern['ip'] . '|' . $_this->__pattern['hostname'] . ')(?::[1-9][0-9]{0,3})?' .
            '(?:\/?|\/' . $validChars . '*)?' .
            '(?:\?' . $validChars . '*)?' .
            '(?:#' . $validChars . '*)?$/i';
        return $_this->_check();
    }
}
```
