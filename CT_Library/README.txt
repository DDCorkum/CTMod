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
- TaintLess by foxlit (unmodified distribution of xml authorized)

To limit download sizes, CT_Library excludes extra files from each library
such as tutorials/instructions or .xml and .toc files that simply point 
to the main code in the .lua.   Please contact the CTMod team if you need 
any help to find these original files from the library authors.
(Hint: they are all on CurseForge, WoWI, or TLY.)



------------------------------
-- CT_RaidAssist

CT_RaidAssist embeds the following addon libraries:
- LibDurability by funkehdude (CC BY-NC-SA 3.0)
- LibHealComm by Shadowed, Azilroka and xbeebs (license unknown), which includes CallbackHandler by nevcairiel (BSD license) and ChatThrottleLib by Mikk (license unknown)

These libraries permit the modern implementation of CT_RaidAssist to
be compatible with non-CT addons for raid management tasks like
checking durability and predicting incoming heals in WoW Classic.

Using a common library allows users more freedom to choose any
compatible addon, so they do not feel pressured to use any
particular one (CT or otherwise) to participate in a raiding guild.

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
25 Oct 2020 (Updated 5 April 2021)