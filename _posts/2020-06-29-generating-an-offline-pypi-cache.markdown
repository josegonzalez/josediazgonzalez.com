---
  title:       "Generating an offline PyPI cache"
  date:        2020-06-29 03:04
  description: ""
  category:    opschops
  tags:
    - deployment
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: false
---

When deploying Python applications to airgapped environments, it becomes necessary to ship application dependencies either with the app or provide a PyPI-like repository. I typically do this by using `pip2pi` within a docker container.

We start with a `Dockerfile`:

```Dockerfile
FROM python:3.6.6-slim-stretch
```

One unfortunate thing is that certain dependencies will require a specific Python version, so it is necessary to pin that version as shown above. The `pip2pi` tool will only download the dependency for the current python version, so you may need to re-run this for a separate python version.

Next, I set both the `WORKDIR` and `PYTHONUNBUFFERED`. I've set the former because of cargo-culting - honestly I can't remember why at the moment - while the latter is set so that running a python `http.server` doesn't buffer logs until container exit.

```Dockerfile
WORKDIR /usr/src/app

ENV PYTHONUNBUFFERED=1
```

Next, we isntall pip2pi. As of the time of writing, currently has a bug wherein it doesn't work for versions of `pip>=19.3`, so I've pinned to `pip==19.2.3`.

```Dockerfile
RUN pip install pip==19.2.3 && \
    pip install pip2pi
```

The `pip2pi` tool can be used to install dependencies from either a single package or a `requirements.txt` file. I'll use the latter, and copy a bunch at once into `/tmp`. These files should be placed in the same directory as the Dockerfile.

```Dockerfile
COPY *.txt /tmp/
```

Because I want to create a repo from two different `requirements.txt` files, I'll create separate pypi repositories and then merge them into one super repository using `dir2pi`, which is included with the `pip2pi` package. I don't call `pip2pi` once for two different files as the `requirements.txt` files may have conflicting versions. Ideally `pip2pi` would support installing conflicting versions so we wouldn't have to manually merge the files, but what can we do.

Note that I copy both `tar.gz` and `whl` files into my super repository.

```Dockerfile
RUN pip2pi /tmp/sample-1 -r /tmp/sample-1-requirements.txt && \
    pip2pi /tmp/sample-2 -r /tmp/sample-2-requirements.txt

RUN rm -rf /tmp/sample-*/simple && \
    mkdir -p packages && \
    cp -f sample-1/*.tar.gz /tmp/packages && cp -f sample-1/*.whl /usr/src/app/packages && \
    cp -f sample-2/*.tar.gz /tmp/packages && cp -f sample-2/*.whl /usr/src/app/packages && \
    dir2pi packages
```

Finally, I creeate a tarball of the packages directory, and set the default command to the python `http.server`. You'll want to start a slightly different command - `SimpleHTTPServer` - for Python 2.7.

```Dockerfile
RUN tar -czf packages.tar.gz packages

CMD ["python", "-m", "http.server", "80"]
```

Assuming everything is setup, you can now build the docker image and start the container:

```shell
docker image build -t pypiserver .
docker container run -p 8081:80 --rm pypiserver
```

I'm exposing the server on port 8081, and am now able to browse to `http://localhost:8081/packages.tar.gz` to fetch a tarball that contains my pypiserver. This container can also be served directly, in which case the pip index-url would be `http://localhost:8081/packages/simple/`.
