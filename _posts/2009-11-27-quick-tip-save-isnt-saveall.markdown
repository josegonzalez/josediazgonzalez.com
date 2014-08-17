---
  title:       "Quick Tip - Model::save() isn't Model::saveAll()"
  description: A very small example on when to use Model::save() versus Model::saveAll()
  category:    CakePHP
  tags:
    - quicktip
    - cakephp
    - model
    - snippet
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Saving multiple records that are related to a primary record?

{% rainbow lang:php %}
<?php echo $this->Page->save($this->data); ?>
{% endrainbow %}

That won't save your related model data. Just the primary model (Page Model in this case).

```php
<?php echo $this->Page->saveAll($this->data, array('validate' => 'first')); ?>
```

This will. Have fun saving your page meta data.


_Note: I added the validate first so that everything would be validated (who doesn't want that?)._
