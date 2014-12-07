---
  title:       "Customizing Bake in CakePHP 3"
  date:        2014-12-03 16:22
  description: "Part 2 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    CakePHP
  tags:
    - cakeadvent-2014
    - cakephp
    - bake
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

> Note: There was an error in the sql schema for the comments table from yesterday's post. If you have the old version, please change it with the following statement in mysql:
>
>   `ALTER TABLE database_name.comments CHANGE comment_id issue_id INT`
>
> You will also need to regenerate your model classes and clear out the cache:
>
>   bin/cake bake model comments --force
>   bin/cake bake model issues --force
>   bin/cake orm_cache clear
>
> I've already corrected yesterdays post, so this change may not be necessary for some users.

CakePHP has always had the Bake shell command - you saw it in action [yesterday](http://josediazgonzalez.com/2014/12/02/designing-a-store-application-in-cakephp/) - but it's always been a bit difficult to work with. You would need to escape your actual php code, making it difficult to actually think about the contents of the template. Thanks to some excellent work by [Andy Dawson](http://ad7six.com/), we now have quite a bit of flexibility in writing bake templates.

In CakePHP, we can use Helpers and elements in our bake templates. As well, CakePHP uses ASP-style tags - `<%`, `<%=`, and `%>` - to execute php code. This sounds weird, but here is an example:

```php
<?php
namespace <%= $namespace %>\View\Helper;

use Cake\View\Helper;
use Cake\View\View;

/**
 * <%= $name %> helper
 */
class <%= $name %>Helper extends Helper {

/**
 * Default configuration.
 *
 * @var array
 */
  protected $_defaultConfig = [];

}
?>
```

Any code in enclosed in `<%` and `%>` is executed by CakePHP - `<%=` can be used to auto-echo variables - while everything else is just normal php. The above template - when baking a `PostHelper`, for instance - turns into the following:

```php
<?php
namespace App\View\Helper;

use Cake\View\Helper;
use Cake\View\View;

/**
 * Post helper
 */
class PostHelper extends Helper {

/**
 * Default configuration.
 *
 * @var array
 */
  protected $_defaultConfig = [];

}
?>
```

As well, the intermediate template is output to your `tmp` directory, meaning you can use the intermediate files to figure out what PHP code will be executed when we *actually* generate your files. One last thing is that the new View-based bake allows us to hook events into the actual bake process, which means we can add/edit/remove any data going into the view. Pretty cool.

Now lets actually customize our bake templates. We're going to customize the controller template to only bake the `index`, `view` and `add` for the issues controller, and modify the views such that the `view` will contain a form that people can use to submit comments. To do so, lets attach an event to Bake. Add the following to your `app/config/bootstrap_cli.php`:

```php
<?php
use Cake\Event\Event;
use Cake\Event\EventManager;
use Cake\Utility\Hash;

EventManager::instance()->attach(function (Event $event) {
    $view = $event->subject;
    $name = Hash::get($view->viewVars, 'name');
    $isController = strpos($event->data[0], 'Bake/Controller/controller.ctp') !== false;
    if ($isController !== false && $name == 'Issues') {
        $view->viewVars['actions'] = ['index', 'view', 'add'];
    }
    if ($isController && $name == 'Comments') {
        $view->viewVars['actions'] = ['add'];
    }
}, 'Bake.beforeRender');
?>
```

> In CakePHP 3, shells all include the new `app/config/bootstrap_cli.php`, as well as the `app/config/bootstrap.php`, which makes cli-only changes like the above a breeze.

This event will:

- Attach to the event `Bake.beforeRender`, which allows us to modify any data going into the template.
- Retrieve the `name` of the template (baked tests do not currently populate this variable).
- If the `filename` ends with `Bake/Controller/controller.ctp` - the template used for controllers - and we are baking "issues", it will force the actions to be just `['index', 'view', 'add']`.
- We also only allow `add` for the `Comments` controller

To test this, lets run bake:

```shell
# ssh onto the vm
vagrant ssh

cd /vagrant/app
bin/cake bake controller comments --force
bin/cake bake controller issues --force
```
Bake will force-overwrite (using the `--force` argument) your existing Controller and it's test. If you open them in your editor, you'll see we only have our desired three actions! The overide for our Comments controller is also in effect :)

One thing we'll want to do is exclude `GET` requests to the `/comments/add` endpoint. Users should only post to it from the form that will be embedded on the `/issues/view` page, and it should also redirect back to the issue. After the line setting actions for the `Comments` controller, add the following:

```php
$view->set('redirect', '["controller" => "Issues", "action" => "view", $comment->issue_id]');
$view->set('requirePost', true);
```

The above two variables will be used in our custom `src/Template/Bake/Element/Controller/add.ctp`. Controllers use elements to bake each action - meaning we can create custom actions as elements in the aforementioned directory - and the add action is no different. While you can copy the core one to that location, I'll just show you the updated version we'll be using:

```php
<%
$compact = ["'" . $singularName . "'"];
if (empty($redirect)) {
    $redirect = "['action' => 'index']";
}
%>

/**
 * Add method
 *
 * @return void
 */
    public function add() {
<% if (!empty($requirePost)) : %>
        if (!$this->request->is('post')) {
            $this->Flash->error('This action requires a post request');
            $this->redirect($this->request->referer());
        }
<% endif; %>
        $<%= $singularName %> = $this-><%= $currentModelName %>->newEntity($this->request->data);
        if ($this->request->is('post')) {
            if ($this-><%= $currentModelName; %>->save($<%= $singularName %>)) {
                $this->Flash->success('The <%= strtolower($singularHumanName) %> has been saved.');
                return $this->redirect(<%= $redirect %>);
            } else {
                $this->Flash->error('The <%= strtolower($singularHumanName) %> could not be saved. Please, try again.');
            }
        }
<%
        $associations = array_merge(
            $this->Bake->aliasExtractor($modelObj, 'BelongsTo'),
            $this->Bake->aliasExtractor($modelObj, 'BelongsToMany')
        );
        foreach ($associations as $assoc):
            $association = $modelObj->association($assoc);
            $otherName = $association->target()->alias();
            $otherPlural = $this->_variableName($otherName);
%>
        $<%= $otherPlural %> = $this-><%= $currentModelName %>-><%= $otherName %>->find('list');
<%
            $compact[] = "'$otherPlural'";
        endforeach;
%>
        $this->set(compact(<%= join(', ', $compact) %>));
    }
```

There are two small changes here. One is that we default the redirect to a string containing the "index" action. This is a custom variable we added - and are overriding just for the `Comments` controller. The `$requirePost` variable is also a custom one, and we inserted a bit of logic to require that the request is a post, otherwise we redirect to the referring page :)

We'll now modify the `view.ctp`  template to include a post form on the issues controller. You can copy the existing one to something we can modify with the following commands:

```shell
TEMPLATE_DIR="src/Template/Bake/"
BAKE_TEMPLATE_DIR="vendor/cakephp/cakephp/src/Template/Bake/"
cd /vagrant/app
mkdir -p $TEMPLATE_DIR
cp $BAKE_TEMPLATE_DIR/Template/view.ctp $TEMPLATE_DIR/Template/view.ctp

## Copy over the form.ctp element file so we can do some light editing
cp $BAKE_TEMPLATE_DIR/Element/form.ctp $TEMPLATE_DIR/Element/form.ctp

## Also copy over the controller's view.ctp action file
cp $BAKE_TEMPLATE_DIR/Element/Controller/view.ctp $TEMPLATE_DIR/Element/Controller/view.ctp

## Create a stub element for later use:
touch $TEMPLATE_DIR/Element/add_related.ctp
```

We need to modify the `form.ctp` to allow us to set a custom action for the `POST` request. The following bit of code should replace the line containing `$this->Form->create`:

```php
<?= $this->Form->create($<%= $singularVar %>, <% if (empty($formOptions)) : %>[]<% else : %><%= var_export($formOptions) %><% endif;%>); ?>
```

I order to show the related form, we'll need to modify the `Bake/Template/view.ctp` we copied over. It's rather long and complicated, but we'll simply add the following line to the end:

```php
<%
if (!empty($relatedForm)) {
  $this->element('add_related', $relatedForm);
}
%>
```

Next, set the following contents in your `add_related.ctp` file:

```php
<%= $this->element('form', $relatedForm) %>
```

Now that the initial setup is done, we need to populate this new `$relatedForm` variable in our `Bake.beforeRender` event. The following event will do just that:

```php
use Cake\ORM\TableRegistry;

EventManager::instance()->attach(function (Event $event) {
    $view = $event->subject;
    $name = Hash::get($view->viewVars, 'pluralHumanName');
    $isAddView = strpos($event->data[0], 'Bake/Template/view.ctp') !== false;
    if ($isAddView && $name == 'Issues') {
        $modelObj = TableRegistry::get('Comments');
        $view->set('relatedForm', [
            'action' => 'Add',
            'schema' => $modelObj->schema(),
            'primaryKey' => (array)$modelObj->primaryKey(),
            'displayField' => $modelObj->displayField(),
            'singularVar' => 'comment',
            'pluralVar' => 'comments',
            'singularHumanName' => 'Comment',
            'pluralHumanName' => 'Comments',
            'fields' => $modelObj->schema()->columns(),
            'associations' => [],
            'keyFields' => [],
            'formOptions' => [
                'url' => [
                    'controller' => 'Comments',
                    'action' => 'add',
                ],
            ],
        ]);
    }
}, 'Bake.beforeRender');
```

> You can always bind more than one listener to the event, so this is fine. If you want, you can also combine the two events, but this is easier to keep track of for me.

If the above seems like a lot, that's because it is. Those variables are necessary for the `form.ctp` element to do it's magic. Unfortunately, there isn't a good way to generically call this for a template from the core, but a solution may come soon. In any case, a couple notes if you bake now:

- There will be another `actions` list right above the form. This is currently not optional in the core `form.ctp` we copied, though you are welcome to make it optional in your own :)
- The `issue_id` field isn't hidden. We cannot arbitrarily pass in options for fields in the core `form.ctp` we copied. Again, you can implement this feature in your own custom element, but we'll try and make this easier before a final release :)
- The form will break because we are missing a `$comment` entity.

To add the `$comment` entity, lets modify the `src/Template/Bake/Element/Controller/view.ctp` we previously copied over. Add the following before the last brace:

```php
<% if (!empty($addRelatedEntity)) : %>
        $<%= $addRelatedEntity['entityName'] %> = $this-><%= $currentModelName %>-><%= $addRelatedEntity['modelName'] %>->newEntity();
        $this->set('<%= $addRelatedEntity['entityName'] %>', $<%= $addRelatedEntity['entityName'] %>);
        $this->set('<%= $pluralName %>', [
          $<%= $singularName %>-><%= $modelObj->primaryKey() %> => $<%= $singularName %>-><%= $modelObj->displayField() %>,
        ]);
<% endif %>
```

This will:

- Create a new entity for the related model
- Set that empty entity for the view
- Set a dummy list for the form containing just the current issue.

To populate the `view.ctp` Controller template properly, we'll need to add one more event to our `app/config/bootstrap_cli.php`:

```php
EventManager::instance()->attach(function (Event $event) {
    $view = $event->subject;
    $name = Hash::get($view->viewVars, 'name');
    $isController = strpos($event->data[0], 'Bake/Controller/controller.ctp') !== false;
    if ($isController !== false && $name == 'Issues') {
        $view->viewVars['addRelatedEntity'] = [
            'modelName' => 'Comments',
            'entityName' => 'comment',
        ];
    }
}, 'Bake.beforeRender');
```

Now lets run bake:

```shell
cd /vagrant/app

bin/cake bake controller issues --force
bin/cake bake view issues --force
```

And we'll have a working form on our view page!

## Homework Time

I won't write *all* the code, but hopefully the above gives you a good idea as to how to modify bake templates. Your homework is:

- Make the form actions optional - and turn them off for embedded forms.
- Create a nicer comment list than the current version.
- Hide the `issue_id` field on the form without removing it completely

Tomorrow's CakeAdvent entry will contain a solution, but this should be a good way for you to start creating your own custom bake templates :) Until then!
