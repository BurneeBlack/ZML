	
	Z-Xtensible Markup Language
	Created: 22/06/22
	Date Format for Project : DD/MM/YY
	
	Schema Validation
	
	
Analysis:
---------

	There is nothing enforcing the structure of a definition or translation file.  
	
	XML has what is called, schema validation, this is another file which
	defines the structure and contents of elements.
	

Needed Additions:
-----------------

	1.	The <?validate schema="path/file.zsd"?> header tag needs added.
	
	2.	The </include> tag will need to become an element of an unordered list, i.e. </includelist>
	
		<includelist>
			<include>path/file.zml</include>
		</includelist>
	
	3.	The </includelist> tag will need a "schema" attribute.
	
		<includelist schema="path/file.zsd">
		</includelist>
	
	4.	A .zsd parser needs written.
	
	5.  Add the "well-formed" and "qualified" flags to tree nodes.
						

The Validate Tag and Schema Attribute - Schematic Inheritance
-------------------------------------------------------------

	- Validation happens on all ZML files.  No exceptions.  This includes internal ZML files.
	
	- ZML includes the "translate_schema.zsd" and "base_schema.zsd".  Usage is controlled, misuaged is detected 
	  and handled.
	  
	Translation File Rules:
	-----------------------
	  
	- Translation files may not contain the <?validate?> tag.
	
	- Translation files are only verified against "translate_schema.zsd".  A valid translation file will be
	  considered "well-formed".
	
	- Attempting to assign another schematic results in an error and the translation file is rejected.
	
	- "translate_schema.zsd" defines the structure of translation files and therefore cannot be overwritten.
	
	- You may not include other translation files using the </include> tag.  This tag defines a defintion file.
	
	- Multiple translation files should be possible in a single archive.  The parser looks for the file name "zml",
	  and not a file extension.  All translation files must be in the root of the archive.
	  
	Definition File Rules:
	----------------------
	
	- Definition files may contain the <?validate?> tag.
	
	- Ommision of the <?validate?> tag produces a warning, but a file found to be "well-formed" can still be parsed.
	
	- All definition files will be validated against at least "base_schema.zsd".  A definition file that is validated
	  against only the base schematic is not considered "qualified".
	  
	The Schema Attribute:
	---------------------
	
	- The "schema" attribute is unique to the </includelist> tag.
	
	- The </includelist> and </include> tags are unique to translation files.  Inclusion or usage of these tags
	  outside of translation and related files are considered errors and can result in rejected schematics.
	  
	- Assigning a schematic to a list of included definition files results in those files being validated by that
	  schematic.
	  
	Schematic Inheritance:
	----------------------
	
	- A secondary tree is created, where every node is a schematic.  This is equivalent to the XML tree,
	  where each node is the root of the DOM (Document Object Model).
	  
	- When that schematic node is created, the schematic instructions of either "translate_schema.zsd" or
	  "base_schema.zsd" are used to initialize the node.  Then the user's schematic instructions are added.
	  
	- The </includelist> tag allows users to validate groups of files against a single schematic, however
	  those files may still include their own schematic declarations.  In this event, inheritance still works
	  the same.  The schematic node will begin with a base file, add in the global schematic, and then finally
	  the local schematic.
	  
	- Inheritance is not necessarily additive.  The upstream schematic has control of downstream rights to
	  modify the contents of a parent schematic inside a node.  This prevents potentially malicious overwrites.
	
		
Difference between "Well-Formed" and "(Un)qualified"
----------------------------------------------------

	- A "well-formed" file will have passed continuity testing.
	
	- A "qualified" file will have also defined a .zsd file for validation and
	  pass that validation.  Because this is a flag there is no "unqualified"
	  flag, "qualified" will simply be false.
	  
		- - The result of validation failure is up to the given schema file, 
			however the parser defaults to ejecting a potentially invalid node.
			Should a file still be "well-formed", it is still possible that the
			file will be parsed.
			
		- - Any file that is found to not be "well-formed" will be ejected from
			parsing and automatically produces errors.  This kind of failure is
			guaranteed to not result in a XML tree node.
			
	- This means that a file may be "well-formed", the XML itself is sound, but
	  it may be "unqualified" because it did not pass the schematic validation.


Differences between ZSD and XSD
-------------------------------

	- There is no need to prefix any element names; there is no namespacing.

	- Schema declarations in XML files, as covered above.



ZSD Introduction
----------------

	A ZSD Schematic describes the structure of a ZML document.

	The ZML Schematic Language is also referred to as ZML Schematic Definition (ZSD).

	ZSD Example:
	------------
	<zsd>
		<element name="playableGhost">
			<complexType>
				<sequence>
					<element name="ghostTrack" maxOccurs="unbounded">
						<complexType>
							<all>
								<element name="trackMin" type="integer"/>
								<element name="trackSec" type="integer"/>
								<element name="fadeIn" type="boolean" minOccurs="0"/>
								<element name="fadeInTicks" type="integer" minOccurs="0"/>
								<element name="fadeOut" type="boolean" minOccurs="0"/>
								<element name="fadeOutTicks" type="integer" minOccurs="0"/>
								<element name="hardVolume" type="decimal" minOccurs="0"/>
								<element name="follows" type="string" minOccurs="0"/>
								<element name="followedBy" type="string minOccurs="0"/>
							</all>
						</complexType>
					</element>
				</sequence>
			</complexType>
		</element>
	</zsd>


	Notes:
	------

	- While camel case is used in examples and documentation, ZML is case insensitive.

	- This example defines a parent element called a "playableGhost"

	- It will contain other elements, thus it is a "complex typed" element.

	- The </sequence> tag defines that the contained elements must be in the given order.

	- Inside, the "ghostTrack" element is defined, however the number of occurances is set to infinity.

	- The "ghostTrack" element is also complex, however it defines the </all> tag, which means any of the
		contained child elements may appear in any order.

	- The first two child elements are required, thus their "minOccurs" attribute is not set to 0.
		- The default value for "minOccurs" and "maxOccurs" is 1, thus "trackMin" and "trackSec" are expected
			to appear once in a "ghostTrack" element, but their order within the element list does not matter.
			
	- The remaining child elements set "minOccurs" to 0, thus these elements are optional.

			  