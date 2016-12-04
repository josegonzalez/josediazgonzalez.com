---
  title:       "File Uploading and Account Management"
  date:        2016-12-04 01:35
  description: "Part 4 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - user-accounts
    - upload
    - files
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/04/working-image-upload.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Managing a User's account

Now that we can login, we'll probably want to be able to update our profile *without* needing to go through the reset password flow. For that, we'll need a account page. I'd also love to be able to personalize the account so that the user will feel at home in his CMS, so we'll allow them to upload a custom image as well. We'll start on account management first. First, lets start by making the `UsersController::edit()` action open to all authenticated users by modifying our `UsersController::isAuthorized()` method:

```php
    /**
     * Check if the provided user is authorized for the request.
     *
     * @param array|\ArrayAccess|null $user The user to check the authorization of.
     *   If empty the user fetched from storage will be used.
     * @return bool True if $user is authorized, otherwise false
     */
    public function isAuthorized($user = null)
    {
        if (in_array($this->request->param('action'), ['edit', 'logout'])) {
            return true;
        }
        return parent::isAuthorized($user);
    }
```

Next, lets go to the `/users/edit` page in our browser. You should get a `NotFoundException`. This is because the `UsersController::edit()` action is currently mapped to the `Crud.Edit` action class in your `AppController::initialize()`, and that action class expects a user id to be passed in. We can fix that and force the edit page to *always* map to the currently logged in user by handling the `beforeHandle` Crud event in our `UsersListener`. First, lets add the following to the list of events handled in our `UsersListener::implementedEvents()` method:

```php
'Crud.beforeHandle' => 'beforeHandle',
```

Next, we'll need to implement the `UsersListener::beforeHandle()` method. As the `beforeHandle` event occurs for *all* executed Crud actions, we'll need to take extra care to only set the action arguments when the current action is the `edit` action.

```php
    /**
     * Before Handle
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeHandle(Event $event)
    {
        if ($event->subject->action === 'edit') {
            $this->beforeHandleEdit($event);

            return;
        }
    }

    /**
     * Before Handle Edit Action
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeHandleEdit(Event $event)
    {
        $userId = $this->_controller()->Auth->user('id');
        $event->subject->args = [$userId];
    }
```

Browse to the `/users/edit` page now and you'll see a lovely form with our current user's information filled out. Yay! Unfortunately, it leaks the existing password, which isn't great. Honestly, I think we should clean up this form a bit:

- The password field should not have the pre-hashed password set
- The password field should only be changed when the password is confirmed
- The `avatar_dir` field shouldn't be shown on the form
- The `avatar` field is actually a form upload.

Let's take care of the first three tasks. We'll start by adding an event handler to remove the hashed `password` during the `Crud.beforeRender` event. Add the following to your `UsersListener::implementedEvents()` method:

```php
'Crud.beforeRender' => 'beforeRender',
```

Next, we'll handle the event in the same `UsersListener` class and unset the `password` property on the Crud-produced entity:

```php
    /**
     * Before Render
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeRender(Event $event)
    {
        if ($this->_controller()->request->action === 'edit') {
            $this->beforeRenderEdit($event);

            return;
        }
    }

    /**
     * Before Render Edit Action
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeRenderEdit(Event $event)
    {
        $event->subject->entity->unsetProperty('password');
    }
```

If you refresh the `/users/edit` page, you should see that the hashed password was removed. Now that this is set, we'll need tomodify the edit form. We previously baked this on the first day of development, so you should have a `src/Template/Users/edit.ctp` file. We'll edit the form section to show the following for now (ignore the sidebar section!):

```php
<div class="users form large-9 medium-8 columns content">
    <?= $this->Form->create($user) ?>
    <fieldset>
        <legend><?= __('Edit User') ?></legend>
        <?php
            echo $this->Form->input('email');
            echo $this->Form->input('password', ['required' => false]);
            echo $this->Form->input('confirm_password');
            echo $this->Form->input('avatar');
        ?>
    </fieldset>
    <?= $this->Form->button(__('Submit')) ?>
    <?= $this->Form->end() ?>
</div>
```

The above adds a `confirm_password` field and also removes the `avatar_dir` field. Finally, add password confirmation, and only save the updated password if it matches the `confirm_password` field *and* both have a value. We'll create a custom validation method - validationAccount - to handle this. Place the following within a trait at `src/Model/Table/Traits/AccountValidationTrait.php`:

```php
<?php
namespace App\Model\Table\Traits;

use Cake\Validation\Validator;

trait AccountValidationTrait
{
    /**
     * Account validation rules.
     *
     * @param \Cake\Validation\Validator $validator Validator instance.
     * @return \Cake\Validation\Validator
     */
    public function validationAccount(Validator $validator)
    {
        $validator = $this->validationDefault($validator);
        $validator->remove('password');
        $validator->allowEmpty('confirm_password');
        $validator->add('confirm_password', 'no-misspelling', [
            'rule' => ['compareWith', 'password'],
            'message' => 'Passwords are not equal',
        ]);
        return $validator;
    }
}
```

> I really love traits. Sorry not sorry?

In this custom validation rule, we inherit from the default rules - defined in the `UsersTable::validationDefault()` method - remove the rules that require a `password` to be set, and add a rule that requires the `password` and `confirm_password` fields to match.

Next, we'll need to add the proper `use` statement to the *inside* of our `UsersTable` class.

```php
use \App\Model\Table\Traits\AccountValidationTrait;
```

To ensure that our custom validation method is actually invoked, we'll need to modify the `UsersListener::beforeHandleEdit()` to tell the `Edit` action class to use it. Here is what I added to that method:

```php
$this->_controller()->Crud->action()->saveOptions(['validate' => 'account']);
```

One thing to note is that we never want to update the password when no password has been set. The `Edit` action class doesn't currently provide an event to directly edit event data, but we still have two options:

- If no `password`/`confirm_password` is set at the time of the `beforeHandle` event, we can just unset it from the request.
- If no `password`/`confirm_password` is set at the time of the `beforeSave` event, we can mark the `password` field as not dirty, and it won't be overwritten.

I prefer the latter, because I don't like screwing around with the incoming request data. Where you perform the scrubbing is up to you. If you do as I do, you'll have to check if `confirm_password` is empty instead of `password`. This is because at the `beforeSave` event, the data has already been set upon the entity, and an empty string has been hashed by the `User::_setPassword()` method. The `confirm_password` field will only be empty if both are empty, otherwise we wouldn't even have gotten to the save phase.

I'll add the following to handle my event to `UsersListener::implementedEvents()`:

```php
'Crud.beforeSave' => 'beforeSave',
```

And here are the methods to add to the `UsersListener`:

```php
    /**
     * Before Save
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeSave(Event $event)
    {
        if ($this->_controller()->request->action === 'edit') {
            $this->beforeSaveEdit($event);

            return;
        }
    }

    /**
     * Before Render Edit Action
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeSaveEdit(Event $event)
    {
        if ($event->subject->entity->confirm_password === '') {
            $event->subject->entity->unsetProperty('password');
            $event->subject->entity->dirty('password', false);
        }
    }
```

Woot! Very close. If you try to submit the form now, you will probably get a validation error - if your browser even lets you submit. Why? The `avatar` field is empty. Even though we've set it to allow `null` values, we need to remove the validation rules surrounding them in our `UsersTable::validationDefault()` method. Remove the rules regarding `avatar` and `avatar_dir`, and you should be off to the races.

Let's save our position now.

```shell
git add src/Controller/UsersController.php src/Listener/UsersListener.php src/Model/Table/Traits/AccountValidationTrait.php src/Model/Table/UsersTable.php src/Template/Users/edit.ctp
git commit -m "Implement initial account management, including password changing"
```

## Setting an image avatar

While image uploading isn't baked into cake - _lol_ - by default, I've included my Upload plugin with the composer app skeleton we used to create the `calico` app. If you don't have it installed, you'll want to install it.

```shell
# install the plugin
composer require josegonzalez/cakephp-upload

# load it in your app
bin/cake plugin load Josegonzalez/Upload
```

> You are welcome and encouraged to try other plugins that might better suit your needs. I wrote mine and like mine, but maybe you prefer a different one.

Next, we'll need to modify our `UsersTable::initialize()` method to add the behavior for our `avatar` and `avatar_dir` fields:

```php
$this->addBehavior('Josegonzalez/Upload.Upload', [
    'avatar' => [
        'fields' => [
            'dir' => 'avatar_dir',
        ],
    ],
]);
```

Next, we'll need to modify our form to show the correct input type for the `avatar` field. I'm also going to conditionally show the avatar on the page so we know what it looks like when it has been uploaded. This is what the form section of the `edit.ctp` should look like:

```php
<div class="users form large-9 medium-8 columns content">
    <?= $this->Form->create($user, ['type' => 'file']) ?>
    <fieldset>
        <legend><?= __('Edit User') ?></legend>
        <?php
            echo $this->Form->input('email');
            echo $this->Form->input('password', ['required' => false]);
            echo $this->Form->input('confirm_password');
            echo $this->Form->input('avatar', ['type' => 'file']);
            if (!empty($user->avatar)) {
                $imageUrl = '../' . preg_replace("/^webroot/", "", $user->avatar_dir) . '/' . $user->avatar;
                echo $this->Html->image($imageUrl, [
                    'height' => '100',
                    'width' => '100',
                ]);
            }
        ?>
    </fieldset>
    <?= $this->Form->button(__('Submit')) ?>
    <?= $this->Form->end() ?>
</div>
```

If you try it out now, you should get a working image upload. Here is what the form looks like for me after an avatar upload:

![working image upload](/images/2016/12/04/working-image-upload.png)

My cat looks handsome, doesn't she?

Before closing out image uploads, we'll want to ignore the `webroot/files` directory in our `.gitignore`. If we do not, we'll end up accidentally committing uploaded files. Please ensure the following line is in your `.gitignore`:

```
/webroot/files
```

Lets commit all our changes as well.

```shell
git add .gitignore src/Model/Table/UsersTable.php src/Template/Users/edit.ctp
git commit -m "Enable avatar uploads"
```

## Validating image uploads

> The following are only *some* of the things you can do to validate that images uploaded are, in fact, images. I would recommend you also:
> - resize the images to remove extra metadata that you may not wish to show
> - only display images that have been sanitized
> - use the [metascan](http://cloudinary.com/blog/how_to_detect_and_prevent_malware_infected_user_uploads) tool to verify the validity of uploads before referencing them on your site.
> This list is also by no means exhaustive, and as security is an important subject, I defer to the experts. Please keep this in mind!

Before allowing just *any* file uploads, lets be sure that they are indeed images. I'd also like to ensure we're not allowing a save to occur when the image upload fails for whatever reason. This will ensure we surface the errors to the users before the UploadBehavior gets to it. The following should be added to your `AccountValidationTrait::validationAccount()` method:

```php
$validator->allowEmpty('avatar');
$validator->add('avatar', 'valid-image', [
    'rule' => ['uploadedFile', [
        'types' => [
            'image/bmp',
            'image/gif',
            'image/jpeg',
            'image/pjpeg',
            'image/png',
            'image/vnd.microsoft.icon',
            'image/x-windows-bmp',
            'image/x-icon',
            'image/x-png',
        ],
        'optional' => true,
    ]],
    'message' => 'The uploaded avatar was not a valid image'
]);
$validator->add('avatar', 'not-upload-error', [
    'rule' => ['uploadError', true],
    'message' => 'There was an error uploading your avatar',
]);
```

- We're allowing the avatar field to be empty. If you don't do this, you're going to see errors when saving the form without an uploaded avatar.
- We're only allowing valid images to be uploaded. Hell, our user can even upload an icon as his avatar if they want.
- We want to make sure that there are no upload errors. Note that *not* uploading a file should not be considered an error. PHP will report it as such, and if we want to allow no files to be uploaded, we have to pass `true` as the first option to the `uploadError` rule.

The above validation rules are included with CakePHP, but you can *also* use custom rules - such as file and image size limiting - that are available from the Upload plugin. Documentation for that is available [here](https://cakephp-upload.readthedocs.io/en/latest/validation.html).

Now that we've validated our image uploads, lets save our changes to the git repository.

```shell
git add src/Model/Table/Traits/AccountValidationTrait.php
git commit -m "Ensure avatar uploads are actually images"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.4](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.4).

Our app now has proper image uploading and account management. We've learned a few new tricks regarding the Crud plugin event system, added advanced validation rules for managing our account, and even showed off our avatar on the form. I think we're more or less done with account management for now. Tomorrow, we'll get into the nitty-gritty of our blog internals, beginning with the initial stages of our posts admin panel.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
