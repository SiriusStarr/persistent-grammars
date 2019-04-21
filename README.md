# persistent-grammars package

This simple Atom package makes Atom remember custom grammars you set for files through them being closed/reopened, rather than having to set them every time you open the file.

## Installation

1. `apm install persistent-grammars`

## Function

Custom grammars are saved in a file named `.atomgrammars` in the folder they reside in.  As such, it may be worth adding this file to your `.gitignore` or equivalent if you use this package.

## Usage


## Settings

Provided through Atom's interface.  You may set a custom name for the `.atomgrammars` file if you so desire; this comes with a number of downsides described in the **Known Issues** section below, however, and is not recommended.

## Known Issues

Grammar files get moved a lot while typing in a custom name.  This seems to be an unavoidable aspect of `atom.config.onDidChange`, since it calls an update on every single change rather than waiting for the field to lose focus or any such thing.

Extant files will (thankfully) not be clobbered by moving the grammar file storage location.  They will get moved out of the way, however.  You will receive a warning about this, so it's not catastrophic.

If you change the location that persistent-grammars stores its info, grammar files will only be moved for open projects.  Any projects that are closed will need to have their files moved manually, unless they were using the default name.  This probably will not be fixed, since it'd require remembering all past custom names used.  As such, we do not recommend you mess around with custom names for the `.atomgrammars` if you've extensively used the package already.

If the `.atomgrammars` file appears to have invalid entries in it, `persistent-grammars` will disable itself.  This is to avoid possible data loss, as ignoring the invalid line and then updating it would lead to overwriting the file, which if it were not a grammar file but some other file would be a bad thing.  If you run into this issue and there is **not** a non-grammar file at the location, please report the issue and include the contents of the file.
