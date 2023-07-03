![Demo](http://i.andrewradev.com/16c7b7ef3f031844391043080b0fe1a5.gif)

## Usage

### Preview popup

If you have a strftime-formatted string in any language, like:

```
echo strftime('%H:%M:%S')
puts DateTime.now.strftime("%x")
```

You can place the cursor over the string and execute the command `:StrftimePopup`. This will open a popup that renders the strftime string applied on the current time and lists all the special characters used with descriptions.

Note that the string must be inside a single- or double-quoted string, so the plugin knows where to find the start and end (though the string doesn't need to be closed).

The popup uses Vim's `popup_create` function, so it won't work on Neovim or on an older Vim version. I'd be open to a PR that implements a Neovim variant.

### Completion function

To make it easier to write the strings, the plugin exposes a completion function that you could plug into `completefunc` or `omnifunc`. Since it's such a specific tool, it's recommended to use a custom mapping that sets `completefunc` temporarily. It's provided as `<Plug>StrftimeComplete` and you could map it to whatever is convenient like this:

``` vim
imap <c-x><c-d> <Plug>StrftimeComplete
```

Note that `<c-x><c-d>` is already mapped to search for "definitions or macros", which is something that might not be commonly used, so I feel comfortable overwriting it, but you can pick whatever mapping you like.

The function will complete from the closest string before the cursor that starts with `%`, and you can write whatever you like, it'll be fuzzy-matched with all the known descriptions. For instance, you might write the following and trigger completion at the end of the line:

``` vim
echo strftime('%full time
```

Triggering this locally, I get the following:

```
%Y Full year (with century) as a decimal number (2023)
%G ISO 8601 week-based full year (with century) as a decimal number (2023)
```

When a completion is picked, the code ("%Y" or "%G") will replace "%full time". You can also just type `%` and trigger completion to get a list of all the entries to go through.

### Modifiers

Both completion and preview will attempt to respect the following modifiers to codes:

* `-`: no leading zeroes
* `_`: blank-padded
* `^`: uppercase

So, `%I` is a zero-padded hour (01), `%-I` will not be padded (1), `%_I` will be space-padded ( 1) and `%^I` won't really produce a difference. However, `%^a` will be an uppercased short day name (MON).

There are other modifiers, `E` and `O`, but they would conflict with just typing normal words during completion, and I haven't had a case for them. I'd be open to adding them if you open an issue.

## Internals

The data is simply one big list of codes and descriptions that is fuzzy-matched. They were taken, with some modifications, from:

- <https://strftime.org/>
- <https://linux.die.net/man/3/strftime>

Since the descriptions are particularly important for fuzzy-finding, if you find yourself searching for something and not getting expected results, please open a github issue, we might be able to tweak the descriptions to make them more findable, or maybe I could add a hidden key with "search keywords" to query instead of the description.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/strftime.vim/blob/main/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/strftime.vim/blob/master/CODE_OF_CONDUCT.md) as well.
