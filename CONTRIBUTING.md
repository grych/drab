## Contributing
Drab welcomes everyone to be a part of the team!

## How to contribute to Drab

### Reporting bugs
If you think you've found a bug, please report it! It really helps to build a better software.

* Check the [Issues](https://github.com/grych/drab/issues) on Github to ensure that this one was not already reported
* Open a new [issue](https://github.com/grych/drab/issues) with the problem description and following information:
    - version of Elixir, Phoenix and Drab
    - code samples

**If you don't want to create an issue on Github, please report it directly to <grych@tg.pl>**

### Correct docs: fix typos, syntax etc
Drab needs help with the documentation: it must be more clear to readers and checked for typos and syntax.

* Create a new [Pull Request](https://github.com/grych/drab/pulls) on Github without reporting it as a bug. Label it as `docs`

### Proposing changes
* Post the proposal on Drab's thread on [elixirforum.com](https://elixirforum.com/t/drab-phoenix-library-for-server-side-dom-access/3277)
* Or create an [issue](https://github.com/grych/drab/issues) with label `change proposal`.

### Contributing to the code
* Clone Drab and make the changes in your copy, in `master`
* Ensure your changes pass all the tests (see [README](https://github.com/grych/drab/blob/master/README.md#tests)). If you are adding functionality, write your own tests. Please use `hound` and `chromedriver` for integration tests.
* Create a [Pull Request](https://github.com/grych/drab/pulls)

## Current areas in need of help
If you are thinking about contributing to Drab, below is the area of topics I suggest to start with.
Don't worry if you find it complicated. Some parts are, but you can always start with the easier stuff, the get deeper and help refactor the core code. I could suggest few areas to work with:

* Issues: search for the issues tagged with ["help wanted"](https://github.com/grych/drab/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22). There is also a tag indicating the level of experience needed to fix this issue.

* Documentation: Drab is the software for developers, so documentation is at least as important as the code itself. It needs review, clarification. There are for sure many parts which are understandable for me, but not for others. Also, starting with docs would let you learn about how Drab works.

* Tutorial and examples: there is a page, https://tg.pl/drab, with few examples. It also could be improved by adding more interesting examples. José suggested creating the example app with multiple chat rooms - maybe something like Slack? - I think it is a good idea, but I never had any time to do it. There is also a need to write a real beginners guide. I was even thinking about writing a complete beginners guide (with short introduction to Elixir, Phoenix, HTML and CSS). I want Drab to be a good way for beginners to start doing webapps without knowing any scary JS frameworks.

* Testing framework: now there is no way to test your commanders, other than running full integration tests. We need to provide conveniences for testing, analogically to `Phoenix.ChannelTest` (and probably based on it). I sill have no idea how it should look like :slight_smile:

* Code review: Drab started as a proof of concept, and had thousands of twists in its short history. There is a lot to improve with code readability. Sometimes I am wondering how it works ;) Again, this would be a good exercise and way to learn how it works. I connected Ebert, you may take a look: https://ebertapp.io/github/grych/drab/

* Bug fixes: https://github.com/grych/drab/issues.

### Anything else
Drop me an email to <grych@tg.pl>.
