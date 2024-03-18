
	Z-Xtensible Markup Language
	Created: 05/02/22
	Date Format for Project : DD/MM/YY

	The name is a bit of a misnomer,  ZML is actually a parser 
	for an XML syntax-like language, created by Sarah Blackburn
	for storage of information outside of standard (G)ZDoom
	project data.

		Just a tidbit, of info, this is my second XML interpreter,
		I did one for Unity in C#.


Basic Mod Concept:
------------------
	It works like most of my mods.  ZML is the base mod, which includes
	just the parser code.  Users then need to decide how to use the mod,
	do they include it with their work, or do they instruct users of
	their mod to download ZML as well?  That decision depends on how the
	other mod works.

	In the case of my project, Viridian Asylum, to allow the game to be
	modded, ZML is included, as a mod (based around how VA is built),
	such that mods to Viridian Asylum can just include ZML data,
	rather than needing code as well.


Parser Concept:
---------------

	Headers : Every mod containing ZML data must contain a header that points to it.
			- Headers are simple files that follow ZML syntax:

				<zml>
					<include>path/file.zml</include>
				</zml>

			- This file should be defined like the ZScript translation unit,
			  thus in the root of the archive.

			- This file must be unique to the archive.

			- This file must be named "zml.txt"

	Defined Tags : Tags are reserved words that the parser will scan for.

			- Tags are defined in a definition file.  This file follows the
			  standards established for such files.

			- This file must be unique to the archive.

			- This file must be located in the root of the directory.

			- This file must be named "zmldefs.txt"

			- ZMLDEFS is more complex as users are defining how their data is stored.

	ZML Files : These are the actual ZML data files

			- These are loaded last.  Tags and headers must be read.

			- These are explicitly error checked to attempt to avoid VM aborting.

			- Where these files are located in the archive are controlled by the
			  header files.  It is recommended that users create a "zml" folder
			  within archives to create namespace that the engine ignores.

			- ZML files may have any name and any extension.  The ".txt" or ".zml"
			  extensions are recommended.


What defines type?
------------------
	Type is expressly defined, either by the parser itself or the user.  No exceptions, ZScript 
	has to know what to cast to.  Both tags and attributes must be typed when defined.


What ZML Does NOT Do:
---------------------
	Anything relating to HTML.

				
Established Syntax For ZML Files:
---------------------------------
	ZML follows standard XML syntax:

	<root>
		<child>
			<subchild>
				<subchild>data</subchild>
			</subchild>
		</child>
	</root>

	This syntax is the same for header and actual ZML data files.

	Tags:
		<zml>data</zml> - openning and closing tags are the standard way of encapsulating data.
		<zml/> - a tag may be self-terminated if the tag is not going to contain children.

	Attributes:
		Attributes are basically variables, thus they are words, or names given to data.
		They follow standard XML syntax:
	
			<tag attributeName=dataOfType></tag>


Esablished Syntax for the ZMLDEFS Lump:
---------------------------------------

	- This lump is not case sensitive.  Everything is assumed to be lowercase, and is handled as such.
	- The brackets and semicolons are required.
	- The presence of a flag in a tag definition is treated as a true value.
	- Standard C-style comments are allowed.

	Keywords - define block sections of the definition:
		tag - a ZML tag.  This may be opened with brackets and further information added.
		attribute - this defines the start of an attribute list that must be opened with brackets.

	Type Words - these result in an enumeration internally that determine what type the data is handled as.
		These are written in double quotes, as strings:
			- t_int
			- t_float
			- t_double
			- t_string
			- t_bool
			- t_none : this type is special as it signifies that a tag, and only a tag, is a root tag that will contain other elements.

	Tag Word - this is the word or name given to the tag, written as a string.
		For example:
			<musicList></musicList>

	Example of a tag definition with flags and attributes:

		tag "tagWord", "typeWord"
		{
			flag;

			attributes
			{
				"attributeName", "typeWord";
			}
		}

	Example of a tag defining only its name and type:

		tag "tagword, "typeWord";
		

Reserved Tags & Attributes:
---------------------------
	Tags:
		<zml></zml> - this is the root tag that defines the file as ZML code
		<include/> - this child tag is used only in ZML header files to direct the parser to 
		     	     actual ZML data to interpret.

