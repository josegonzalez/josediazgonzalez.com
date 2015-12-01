---
  title:       "Conditional Loading of Helpers"
  date:        2009-09-03 00:00
  description: Example of conditionally loading helpers in a view
  category:    cakephp
  tags:
    - cakephp
    - helpers
    - conditional
    - quicktip
    - cakephp 1.2
    - cakephp 1.3
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

```php
class TumblesController extends TumbleAppController {
    function beforeRender() {
        parent::beforeRender()
        $this->_configureHelpers($this->params['action']);
    }

/**
 * Configures the helpers for the current action
 *
 * @author Jose Diaz-Gonzalez
 */
    function _configureHelpers($action) {
        switch ($action) {
            case 'index' :
                $this->helpers[] = 'Text';
                $this->helpers[] = 'Time';
                break;
            case 'view' :
                $this->helpers[] = 'HtmlCache.HtmlCache';
                $this->helpers[] = 'Text';
                $this->helpers[] = 'Time';
                break;
            case 'admin_add' :
                $this->helpers[] = 'Tagging.Tagging';
                $this->helpers = array_merge($this->helpers, array('Wysiwyg.Wysiwyg' => array('editor' => Configure::read('AppSettings.application.editor'))));
                break;
            case 'admin_preview' :
                $this->helpers = array_merge($this->helpers, array('Wysiwyg.Wysiwyg' => array('editor' => Configure::read('AppSettings.application.editor'))));
                break;
        }
    }
}
```
