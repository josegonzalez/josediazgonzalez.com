---
  title:       "Toggle Behavior"
  description: Toggle CakePHP Behavior for toggling boolean model fields in CakePHP
  date:        2009-08-13 00:00
  category:    CakePHP
  tags:
    - cakephp
    - toggle
    - behaviors
    - cakephp bin
    - quicktip
    - cakephp 1.2
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

## UPDATE: Fixed link to latest revision of ToggleBehavior
There is apparently already something out there that does this, but here is my "ToggleBehavior". Does not really do callbacks, but it works well otherwise. I'll try to fix the callbacks sometime soon.

It's a study on how to build a usable feature in CakePHP, this time being a behavior. Each revision is stored on the [CakePHP Bin](http://bin.cakephp.org), and you'll see a slow progression from something quick and dirty to a behavior that follows most CakePHP conventions. About the only convention not followed is the non-use of the Ternary Operator. I use it as I think it is neat, but you can make a new revision that doesn't.

Cheers if it works for you, and feedback is always welcome!

[Original Bin](http://bin.cakephp.org/saved/49042)

```php
/**
 * Toggle Model Behavior
 *
 * Allows you to toggle default fields or a specific field/fields
 * Can also toggle a field on or off explicitly
 *
 * @package app.models.behaviors
 * @author Jose Diaz-Gonzalez
 * @version 1.4.7
 **/
class ToggleBehavior extends ModelBehavior {
/**
 * Default settings for a model that has this behavior attached.
 *
 * @var array
 * @access protected
 */
    protected $_settings = array(
        'fields' => array('active'),
        'callbacks' => false
    );
/**
 * Initiate behaviour for the model using settings.
 *
 * @param AppModel $Model Model instance
 * @param array $config Settings to override for model.
 * @access public
 */
    function setup(&$model, $config = array()) {
        $this->settings[$model->alias] = $this->_settings;

        //merge custom config with default settings
        $this->settings[$model->alias] = array_merge($this->settings[$model->alias], (array)$config);
    }

/**
 * Toggles the fields
 *
 * @param AppModel $Model Model instance
 * @param mixed $id Optional The ID of the record to read
 * @param array $fieldNames name of fields to be toggled
 * @return mixed Array of non-existing fields, saved data/true if everything went well, or false if saving failed
 * @author Jose Diaz-Gonzalez
 **/
    function toggle(&$model, $fieldNames = array(), $id = null) {
        return $this->_turnFields($model, $fieldNames, 'toggle', $id);
    }

/**
 * Toggles the fields on
 *
 * @param AppModel $Model Model instance
 * @param mixed $id Optional The ID of the record to read
 * @param array $fieldNames name of fields to be toggled
 * @return mixed Array of non-existing fields, saved data/true if everything went well, or false if saving failed
 * @author Jose Diaz-Gonzalez
 **/
    function turnOn(&$model, $fieldNames = array(), $id = null) {
        return $this->_turnFields($model, $fieldNames, 1, $id);
    }

/**
 * Toggles the fields off
 *
 * @param AppModel $Model Model instance
 * @param array $fieldNames name of fields to be toggled
 * @param mixed $id Optional The ID of the record to read
 * @return mixed Array of non-existing fields, saved data/true if everything went well, or false if saving failed
 * @author Jose Diaz-Gonzalez
 **/
    function turnOff(&$model, $fieldNames = array(), $id = null) {
        return $this->_turnFields($model, $fieldNames, 0, $id);
    }

/**
 * Does the grunt work for toggling
 *
 * @param AppModel $Model Model instance
 * @param array $fieldNames name of fields to be toggled
 * @param mixed $type Either the string "toggle" or the value to save
 * @param mixed $id Optional The ID of the record to read
 * @return mixed Array of non-existing fields, saved data/true if everything went well, or false if saving failed
 * @author Jose Diaz-Gonzalez
 **/
    function _turnFields(&$model, $fieldNames = array(), $type = null, $id = null) {
        if (!is_null($id) and !empty($id)) {
            $id;
        } else {
            if (is_array($this->id)) {
                $id = $this->id[0];
            } else {
                $id = $this->id;
            }
        }

        $errors = array();
        if (!empty($fields)) {
            $fields = $fieldNames;
        } else {
            $fields = $this->settings[$model->alias]['fields'];
        }
        $model->id = $id;

        $arr = $this->_checkFields($model, $fields);
        $errors = $arr['errors'];
        $fields = $arr['fields'];
        if (!empty($errors)) {var_dump($errors);die;
            return $errors;
        }

        switch ($type) {
            case 'toggle' :
                foreach ($fields as $field) {
                    $field = $model->escapeField($field);
                    $toSave[$field] = 'NOT ' . $field;
                }
                break;
            default:
                foreach ($fields as $field) {
                    $toSave[$field] = $type;
                }
                break;
        }

        if ($this->settings[$model->alias]['callbacks']) {
            $model->beforeSave();
            $data = $model->updateAll($toSave, array($model->escapeField() => $id));
            $model->afterSave();

        } else {
            $data = $model->updateAll($toSave, array($model->escapeField() => $id));
        }
        return $data;
    }

/**
 * Checks the model to ensure that the fields do indeed exist
 *
 * @param AppModel $Model Model instance
 * @param array $fieldNames name of fields to be toggled
 * @return array Fields and Errors in a single array
 * @author Jose Diaz-Gonzalez
 **/
    function _checkFields(&$model, $fields) {
        $errors = array();

        foreach ($fields as $key => $field) {
            if(!$model->hasField($field)) {
                unset($fields[$key]);
                $errors[] = $field;
            }
        }

        return array('fields' => $fields, 'errors' => $errors);
    }
}
```
