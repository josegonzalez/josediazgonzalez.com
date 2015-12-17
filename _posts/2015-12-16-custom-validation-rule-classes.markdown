---
  title:       "Custom Validation Rule Classes"
  date:        2015-12-16 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - rules
    - validation
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

I was asked yesterday if I could elaborate on my `OwnedByCurrentUser` rule class. I'll post it here, but also post on my process for developing rules.

## Organization

First off, I *hate* having anonymous functions:

- They are harder to test in isolation of the enclosing scope.
- They make it more difficult to reason about classes because of the implicit extra scope/binding of the callable.
- I think they look silly.

I definitely think they have their place - configuring the CRUD Plugin is one - but normally I try to stay away from them if possible. Instead, I use [invokable callable classes](/2015/12/06/invoking-callable-classes/).

For rules, I normally place my callable classes in `src/Form/Rule`. Here is what our initial `OwnedByCurrentUser` rule looks like:

```php
<?php
namespace App\Form\Rule;
class OwnedByCurrentUser
{
    /**
     * Performs the check
     *
     * @param mixed $value The data to validate
     * @param array $context A key value list of data that could be used as context
     * during validation. Recognized keys are:
     * - newRecord: (boolean) whether or not the data to be validated belongs to a
     *   new record
     * - data: The full data that was passed to the validation process
     * - field: The name of the field that is being processed
     * - providers: associative array with objects or class names that will
     *   be passed as the last argument for the validation method
     * @return bool
     */
    public function __invoke($value, array $context = null)
    {
    }
}
?>
```

## Filling it in

When I write a rule, I'll first write it to handle one very specific case. In this particular application, I had to ensure that a particular `Battle` was owned by a participant in the battle before allowing them to perform certain actions. My invoke looked like so:

```php
public function __invoke($value, array $context = null)
{
    $table = \Cake\ORM\TableRegistry::get('Battles');
    return !!$table->find()->where([
      'id' => (int)$value,
      'user_id' => $userId,
    ])->firstOrFail();
}
```

The above sort of works:

- It actually throws a `Cake\Datasource\Exception\RecordNotFoundException` exception, which is incorrect for my use case, since I don't want validation rules to throw exceptions
- I wasn't sure where I was passing in the `$userId`. The `$context` maybe?
- I'm offloading a lot of logic into the database. What if I don't have compound index on `id/user_id`? That would slow down this part of the app (maybe not a concern).
- There was a table where I was thinking of re-using this in the near future that used `creator_id` instead of `user_id` to denote who owned the record (legacy applications, am I right?). This was hardcoded to the one field, which would mean more copy-pasting. I also couldn't modify the table that was being checked. Boo.

Once I had a few tests going that brought up the above issues, I knew I had to refactor it.

## Fixing issues

I took a step back and realized I wanted to instantiate rules and then invoke them several times. This meant modifying the rule instance state, as well as passing in an initial state. First, lets add a constructor:

```php
protected $_alias;
protected $_userId;
protected $_fieldName;

/**
 * Performs the check
 *
 * @param string $alias Table alias
 * @param mixed $userId A string or integer denoting a user's id
 * @param string $fieldName A name to use when checking an entity's association
 * @return void
 */
public function __construct($alias, $userId, $fieldName = 'user_id')
{
    $this->_alias = $alias;
    $this->_userId = $userId;
    $this->_fieldName = $fieldName;
}

public function setTable($alias)
{
    $this->_alias = $alias;
}

public function setUserId($userId)
{
    $this->_userId = $userId;
}

public function setFieldName($fieldName)
{
    $this->_fieldName = $fieldName;
}
```

Each field is a protected field - meaning I can extend this easily by subclassing - and all have setters - meaning I can reuse a rule instance if necessary. Next I needed to modify the `__invoke()` method to use my customizations:

```php
public function __invoke($value, array $context = null)
{
    // handle the case where no userId was
    // specified or the user is logged out
    $userId = $this->_userId;
    if (empty($userId)) {
        return false;
    }

    // use the Table class specified by our configured alias
    $table = \Cake\ORM\TableRegistry::get($this->_alias);

    // Don't make the database do the heavy-lifting
    $entity = $table->find()->where(['id' => (int)$value])->first();
    if (empty($entity)) {
        return false;
    }

    // Ensure any customized field matches our userId
    return $entity->get($this->_fieldName) == $userId;
}
```

### Wrapping it up

From yesterday's post, here is how the rule is invoked:

```php
protected function _buildValidator(Validator $validator)
{
    // use $this->_user in my validation rules
    $userId = $this->_user->get('id');
    $validator->add('id', 'custom', [
        'rule' => function ($value, $context) use ($userId) {
            // reusing an invokable class
            $rule = new OwnedByCurrentUser('Battles', $userId);
            return $rule($value, $context);
        },
        'message' => 'This photo isn\'t yours to battle with'
    ]);

    // This should also work
    $validator->add('id', 'custom', [
        'rule' => new OwnedByCurrentUser('Battles', $userId),
        'message' => 'This photo isn\'t yours to battle with'
    ]);

    // As should this (and you can now re-use the rule)
    $rule = new OwnedByCurrentUser('Battles', $userId);
    $validator->add('id', 'custom', [
        'rule' => $rule,
        'message' => 'This photo isn\'t yours to battle with'
    ]);
}
```

## Mopping up

When I first found out I could do this, I was quite delighted by it. Validation rules have always been a pain to test, and this was as good as it got. I now have an easy to understand class that is both easily testable and gives me increased code reuse.
