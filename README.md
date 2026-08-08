# cobfortune
A rewrite of fortune-mod in COBOL.

Fortune Cookie Data Files
-------------------------

The fortune cookie data files included with this project are taken from
the fortune-mod project:

    https://github.com/shlomif/fortune-mod

which is derived from the classic BSD / NetBSD fortune program.

The fortune-mod code is licensed under the 4-clause BSD license:

    Copyright (c) 1986, 1993
        The Regents of the University of California.  All rights reserved.

    (See licenses/fortune-mod-COPYING.txt for the full text, including the
    advertising clause and disclaimer.)

The data files are a large compilation of short quotations gathered from
many sources. The original BSD "Notes" file states that the collection was
assembled under a fair-use understanding for non-profit use and that no
warranty is made regarding attributions or exactness of the quotes.
Individual quotations may still be subject to their original copyrights.

Content Notice & Historical Preservation
This repository includes the complete set of legacy fortune cookie data files from https://github.com/shlomif/fortune-mod, including offensive or sensitive material, solely for the sake of completeness. The original license, documentation, and notes accompanying these files — including those for the offensive set — have been retained intact.
Inclusion of these data files does not constitute endorsement, approval, or condoning of any ideas, opinions, or language they contain. They are preserved in their unedited original form so that users retain full control over their own installation and configuration choices.
Offensive content is strictly opt-in at two levels:

It must be explicitly enabled at build time with --include-offensive.
Even when compiled in, cobfortune will not display it at runtime unless the user passes -o or -a.
