---
  title: The Daily Dev Log - 3
  category: Dev Log
  tags:
    - daily-dev-log
  description: Defining joins in CakePHP finds is simple, but can result in weird sql statements if used in conjunction with Containable.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

For those that didn't know, you can specify a custom join in CakePHP by doing the following:

```php
$this->Category->find('list', array(
     'fields' => array('id', 'name'),
     'joins' => array(array(
             'table' => 'header_categories',
             'alias' => 'HeaderCategory',
             'type' => 'inner',
             'conditions'=> array(
                     'HeaderCategory.category_id = Category.id',
             )
     ))
));
```

You can also specify the `contains` to use:

```php
$this->Category->find('list', array(
     'fields' => array('id', 'name'),
     'contain' => array('FooterCategory')
));
```

What you cannot do is use them in conjunction, as the `contain` key is evaluated before the `joins` key. That breaks the following type of code:

```php
class Item extends AppModel {

    public $hasOne = array(
        'SearchItemTag' => array(
            'table' => 'items_tags',
            'className' => 'ItemsTag',
            'type' => 'INNER',
            'foreignKey' => false,
            'conditions'=> array('SearchItemTag.item_id = Item.id')
        ),
    );

/**
 * Finds all items that have ANY of the tags passed in
 *
 * @param string $state
 * @param array $query
 * @param array $results
 * @return array
 */
    public function _findWithanyoftags($state, $query, $results = array()) {
        if ($state == 'before') {
            if (empty($query['conditions'])) {
                $query['conditions'] = array();
            }

            $query['conditions'][$this->alias . '.user_id'] = Authsome::get('id'))

            if (!empty($query['filters'])) {
                $query['group'] = array('Item.id');
                $query['joins'] = array(array(
                    'table' => 'tags',
                    'alias' => 'Tag',
                    'type' => 'inner',
                    'foreignKey' => false,
                    'conditions'=> array('and' => array(
                        'Tag.id = SearchItemTag.tag_id',
                        'Tag.id' => $query['filters']
                    )
                )));
                $query['contain'] = array('SearchItemTag', 'Tag');
            } else {
                $query['contain'] = array('Tag');
            }

            $query['order'] = array($this->alias . '.created DESC');

            if (!empty($query['operation'])) {
                unset($query['contain']);
                return $this->_findPaginatecount($state, $query, $results);
            }
            return $query;
        } elseif ($state == 'after') {
            if (!empty($query['operation'])) {
                return $this->_findPaginatecount($state, $query, $results);
            }

            return $results;
        }
    }
}
```

That breaks hysterically, since the query produced throws the following error in MySQL: `Unknown column 'SearchItemTag.tag_id' in 'on clause'`. Rewriting the query such that the `SearchItemTag` join comes before the one specified in `joins` fixes the issue, so you'll either need to specify that `join` as a relation or specify the `contain` as a `join`. Just a quick tip, in case anyone was wondering why this occurs.
