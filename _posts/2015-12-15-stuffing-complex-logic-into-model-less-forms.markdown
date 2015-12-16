---
  title:       "Stuffing Complex Logic into Model-less Forms"
  date:        2015-12-15 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - forms
    - service
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

One new feature of CakePHP 3 is the ability to have [Model-less form classes](http://book.cakephp.org/3.0/en/core-libraries/form.html). These are typically useful for stuff like contact forms that might send an email:

```php
<?php
namespace App\Form;

use Cake\Form\Form;
use Cake\Form\Schema;
use Cake\Mailer\Email;
use Cake\Validation\Validator;

class ContactForm extends Form
{
    // require some data
    protected function _buildSchema(Schema $schema)
    {
        return $schema->addField('name', 'string')
            ->addField('email', ['type' => 'string'])
            ->addField('body', ['type' => 'text']);
    }

    // validate the incoming data
    protected function _buildValidator(Validator $validator)
    {
        return $validator->add('name', 'length', [
                'rule' => ['minLength', 10],
                'message' => 'A name is required'
            ])->add('email', 'format', [
                'rule' => 'email',
                'message' => 'A valid email address is required',
            ]);
    }

    // actually send an email
    protected function _execute(array $data)
    {
        $email = new Email('default');
        return $email->from([$data['email'] => $data['name']])
            ->to('mail@example.com', 'Mail Example')
            ->subject('Contact Form')
            ->message($data['body'])
            ->send();
    }
}
?>
```

Neato burrito. One thing I love about this is the ability to have complex validation rulesets for specific actions. For instance, on a blog, I might have complex edit action that needs to check for editing writes before allowing a user to do anything:

```php
<?php
namespace App\Form;

use Cake\Form\Form;

class PostEditForm
{
    protected $_user = null;
    public function __construct(array $user = [])
    {
        $this->_user = $user;
        return $this;
    }

    protected function _buildValidator(Validator $validator)
    {
      // use $this->_user in my validation rules
      $userId = $this->_user->get('id');
      $validator->add('id', 'custom', [
          'rule' => function ($value, $context) use ($userId) {
              // reusing an invokable class
              return (new OwnedByCurrentUser($userId))->__invoke($value);
          },
          'message' => 'This photo isn\'t yours to battle with'
      ]);
    }
  }
?>
```

Nifty, huh? Usually I end up saving new records in my `_execute()` method as well. Here is what that looks like in one of my form classes:

```php
protected function _execute(array $data)
{
    $battle_id = Hash::get($data, 'id', null);
    $photo_id = Hash::get($data, 'photo_id', null);
    $battles = TableRegistry::get('Battles');
    $photos = TableRegistry::get('Photos');

    $battle = $battles->find('Battle', [
        'battle_id' => $battle_id,
    ])->firstOrFail();

    if ($battle->confirmed != null) {
        throw new MethodNotAllowedException('Battle has already been updated');
    }

    $photo = $photos->get($photo_id);

    $battle->confirmed = true;
    $battle->rival->photo = $photo;
    if ($battles->save($battle)) {
        return $battles->find('Battle', $battle->toFind())->firstOrFail();
    }

    $exception = new ValidationException('There are errors in the data you submitted');
    $exception->errors($battle->errors());
    throw $exception;
}
```

 Why? Because it turns certain complex actions into the following:

```php
public function edit()
{
    $authedUser = $this->Auth->user();
    $post = (new PostEditForm($authedUser))->execute($this->request->data);
    $this->set(['post' => $post]);
}
```

Instead of litering logic across:

- a custom validation method in my model
- a controller action
- some other random model method or protected controller method

I can group it all together into one, logical unit that can be easily unit tested for various types of input. A side-benefit of this is that if I *absolutely* need to, I can always re-use a given action's logic with as few as three lines of code within say, idk, a console shell.
