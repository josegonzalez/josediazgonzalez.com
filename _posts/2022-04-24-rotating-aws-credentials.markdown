---
category: installation
comments: true
date: 2022-04-24 16:04
description: Keeping your credentials fresh for general infra hygiene
disable_advertisement: false
layout: post
published: true
sharing: true
tags:
- aws
- cli
- os-x
title: Rotating AWS Credentials
---
<p>I recently picked up managing my infrastructure again and found that I had... ancient AWS credentials for my personal AWS account. While I did want to write a new tool for this, I found <a href="https://github.com/stefansundin/aws-rotate-key">stefansundin/aws-rotate-key</a> which appears to handle this quite well.</p>

<p>Installing was easy (on a mac):</p>

```shell
brew install aws-rotate-key
```

<p>After which I was able to rotate my key:</p>

```shell
aws-rotate-key --profile my-aws-personal
```

<p>The nice thing here is that it allowed me to specify a profile and also prompted me before deleting any keys.</p>

<p>AWS has a <a href="https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/">blog post</a> on how to do this with the aws-cli, but honestly I'm not very enthused about the idea of manually running a ton of commands, so I think I'll continue with the <code>aws-rotate-key</code> method for now.</p>