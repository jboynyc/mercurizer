Mercurizer
==========

Mercurizer is a simple web app using Racket for the backend and IntercoolerJS
for the frontend. It takes a URL and displays the rendered markup as processed
by the Mercury Web Parser.

To run, first set the ``MERCURY_API_KEY`` environment variable.

Alternately, you can deploy Mercurizer to Heroku. Follow these simple steps:

::

    $ heroku git:remote -a my-app-name
    $ heroku buildpacks:set https://github.com/lexi-lambda/heroku-buildpack-racket
    $ heroku config:set RACKET_VERSION=current
    $ heroku config:set MERCURY_API_KEY=<your key here>
    $ git push heroku master

Consult `this blog post
<https://lexi-lambda.github.io/blog/2015/08/22/deploying-racket-applications-on-heroku/>`_
for additional guidance.
