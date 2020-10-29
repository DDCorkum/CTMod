------------------------------
-- Overall CTMod license

CTMod remains "all rights reserved"; specifically, 
it is requested to contact the team before modifying or redistributing.

The CTMod team has included the following individuals over time:
- Cide (original team member)
- TS (original team member)
- Resike (since 2014)
- Dahk Celes / DDCorkum (since 2017)



------------------------------
-- CT_Library

CT_Library embeds the following addon libraries:
- LibStub by Kaelten et al. (public domain)
- LibDeflate by Haoqian He (zlib license)
- AceSerializer-3.0 by Nevcairiel et al. (see Libs\Ace3\Ace3-License.txt)

CT_Library also embeds work by foxlit at Townlong-Yak, to mitigate 'taint' 
issues in World of Warcraft's API associated with UIDropDownMenu. 
These workarounds are not disibuted with an explicit license so care should be
taken to review the original work at Townlong-Yak. (Presumably TLY intends 
for addons to widely use this code while giving credit where it is due.)

To limit download sizes, CT_Library excludes extra files from each library
such as tutorials/instructions or .xml and .toc files that simply point 
to the main code in the .lua.   Please contact the CTMod team if you need 
any help to find these original files from the library authors.
(Hint: they are all on popular download sites, like CurseForge.)



------------------------------
-- CT_RaidAssist

CT_RaidAssist embeds other libraries to provide addon communication that
is compatible with non-CT addons.  This is done so users do not feel
pressured to use any single addon (CT or otherwise) to participate
in a raiding guild.

To further give users control over their privacy, CT_RaidAssist also
adds a single conditional statement at the top of certain embedded 
lua files to toggle whether or not the library should be installed.
This conditional only interrupts CT_RaidAssist from installing the
embedded library; it does not stop any other addon from installing it.

This small change is intended to balance user privacy rights, and the CTMod
team appologizes if this has inadvertently violated the spirit of any license.




D.D. Corkum
aka. Dahk Celes
CTMod Team
25 Oct 2020