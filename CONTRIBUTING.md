## Contributing
Drab team welcomes everyone to be a part of the team!

## How to contribute to Drab

### Reporting bugs
If you think you've found a bug, please report it! It really helps to build a better software.

* Check the [Issues](https://github.com/grych/drab/issues) on Github to ensure that this one was not already reported
* Open a new [issue](https://github.com/grych/drab/issues) with the problem description and following information:
    - version of Elixir, Phoenix and Drab
    - code samples

** If you don't want to create an issue on Github, please report it directly to <grych@tg.pl> **

### Correct docs: fix typos, syntax etc
Drab needs help with the documentation: it must be more clear to readers and checked for typos, sytax.

* Create a new [Pull Request](https://github.com/grych/drab/pulls) on Github without reporting it as a bug. Label it as `docs`

### Proposing changes
* Post the proposal on Drab's thread on [elixirforum.com](https://elixirforum.com/t/drab-phoenix-library-for-server-side-dom-access/3277)
* Or create an [issue](https://github.com/grych/drab/issues) with label `change proposal`.

### Contributing to the code
* Clone Drab and make the changes in your copy, in `master`
* Ensure is pass all the tests (see [README](https://github.com/grych/drab/blob/master/README.md#tests)). If you adding functionality, write your own tests. Please use `hound` for integration tests.
* Create a [Pull Request](https://github.com/grych/drab/pulls)


## Current areas needed help
If you are thinking about contributing to Drab, below is the area of topics I suggest to start.
Don't worry if you find it complicated. Some parts are, but you can always start with the easier stuff, the get deeper and help refactor the core code. I could suggest few areas to work with:

* Documentation: Drab is the software for developers, so documentation is at least the same important as the code. It needs review, clarification. There are for sure many parts which are understandable for me, but not for others. Also, starting with docs would let you learn how Drab works

* Tutorial and examples: there is a page, https://tg.pl/drab, with few examples. It also could be improved, more interesting examples added. José suggested creating the example app with multiple chat rooms where a user can see the contents in one but not in another - I think it is a good idea, but I never had time to do it.

* `Drab.Modal` is the module to display bootstap modal window and wait for an answer. I find it very useful when you want to ask user about something. See few examples here: https://tg.pl/drab/docs#modal. 
Unfortunately, this library depends on jQuery and bootstrap, so its usage is limited. The goal is to get rid both jQuery and bootstrap, make it independent (but allow user to provide own CSS or even own CSS+HTML), but keep the existing API.

* Testing framework: now there is no way to test your commanders, other than full integration tests. We need to provide conveniences for testing, analogically to Phoenix.ChannelTest (and probably based on it). I sill have no idea how it should look like :slight_smile:

* Code review: Drab started as a proof of concept, and had thousands of twists in its short history. There is a lot to improve with code readability. Sometime I am wondering how does it works ;) Again, this would be a good exercise and way to learn how it works. I connected Ebert, you may take a look: https://ebertapp.io/github/grych/drab/

* Bug fixes: https://github.com/grych/drab/issues. Please assign yourself to the issue if you want to work on it, to prevent double job.

### Anything else
Drop me an email to <grych@tg.pl>.
