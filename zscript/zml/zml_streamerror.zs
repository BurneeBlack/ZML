/*
    What : ZML Parser Error Class Definition
    Who : Sarah Blackburn
    When : 27/03/2022

*/

class StreamError
{
    enum ERRID
    {
        ERROR_ID_IDKWHAT,
        ERROR_ID_OPENCOMMENT,
        ERROR_ID_INVALIDCHAR,
        ERROR_ID_OPENSTRING,
        ERROR_ID_UNEXPECTEDCODE,
        ERROR_ID_MISSINGCOMMA,
        ERROR_ID_MISSINGEOB,
        ERROR_ID_MISSINGOPENBRACE,
        ERROR_ID_MISSINGCLOSEBRACE,
        ERROR_ID_UNKNOWNIDENTIFIER,
        ERROR_ID_EMPTYFILE,
        ERROR_ID_INVALIDTYPE,

        ERROR_ID_MISSINGLESSTHAN,
        ERROR_ID_MISSINGGREATERTHAN,
        ERROR_ID_UNCLOSEDTAG,
        ERROR_ID_UNKNOWN_XML_IDENTIFIER,
        ERROR_ID_UNKNOWN_XML_ATTRIBUTE,
        ERROR_ID_NODE_DISORDER,
    };

    ERRID CodeId;
    int LumpNumber,
        LumpHash,
        InternalLine,
        FileLine;

    string CodeString,
        LumpName,
        Message,
        StreamBufferContents,
        FullLine;

    StreamError Init(int CodeId, int LumpNumber, int LumpHash, string LumpName, string Message, string StreamBufferContents, int InternalLine, int FileLine, string FullLine)
    {
        self.CodeId = CodeId;
        self.CodeString = errorToString(CodeId);
        self.LumpNumber = LumpNumber;
        self.LumpHash = LumpHash;
        self.LumpName = LumpName;
        self.Message = Message;
        self.StreamBufferContents = StreamBufferContents;
        self.InternalLine = InternalLine;
        self.FileLine = FileLine;
        self.FullLine = FullLine;
        return self;
    }

    /*
        WHAT IS WITH THE BIRD CODES?

        lol, ok, this parser is actually version 3, not version 0.1.
        It's version 0.1, the functional parser.

        This is version 3 of the code body itself, the first version to reach
        production versioning.

        Version 1 did not work at all.  Version 2 resulted from some study of
        the concept of parsers and other peoples' code.  It worked but did not
        error check.  It worked on a principle I called the "boolean flock",
        basically a bunch of switches to establish "context" to the parser.

        Version 2 was unmanagable because of the boolean flock, so I started
        again, salvaging a few things, but with one goal, kill the flock.  In real 
        life, someone had happened to mention that a flock of crows is called a 
        murder of crows, and because I am a fan of Incubus, especially A Crow Left 
        of the Murder, I named the new working parser concept, Murdered Crows, 
        because I had done just that, I had killed the flock. I now had a working 
        parser concept!

        The error messages are a celebration of that event, when I killed the flock.
            - Maybe this is the spiritual successor?
        ZMLDEFS error codes are all types of blackbirds.
        XML errors are different parots!

        I also love birds!
    */
    private string errorToString(int t)
    {
        switch (t)
        {
            // ZMLDEFS/General
            case ERROR_ID_OPENCOMMENT:              return "Cuban Bullfinch : OPEN_COMMENT";
            case ERROR_ID_INVALIDCHAR:              return "Brewer's Blackbird : INVALID_CHAR";
            case ERROR_ID_OPENSTRING:               return "Lark Bunting : OPEN_STRING";
            case ERROR_ID_UNEXPECTEDCODE:           return "Hooded Crow : UNEXPECTED_CODE";
            case ERROR_ID_MISSINGCOMMA:             return "Common Grackle : MISSING_COMMA";
            case ERROR_ID_MISSINGEOB:               return "Great Cormorant : MISSING_EOB";
            case ERROR_ID_MISSINGOPENBRACE:         return "Crested Myna : MISSING_OPEN_BRACE";
            case ERROR_ID_MISSINGCLOSEBRACE:        return "Black Pheobe : MISSING_CLOSE_BRACE";
            case ERROR_ID_UNKNOWNIDENTIFIER:        return "Bronzed Cowbird : UNKNOWN_IDENTIFIER";
            case ERROR_ID_EMPTYFILE:                return "Eurasian Blackbird : EMPTY_FILE";
            case ERROR_ID_INVALIDTYPE:              return "Eastern Kingbird : INVALID_TYPE";
            // XML Specific
            case ERROR_ID_MISSINGLESSTHAN:          return "Fischer's Lovebird : MISSING_LESS_THAN";
            case ERROR_ID_MISSINGGREATERTHAN:       return "Rosella Parakeet : MISSING_GREATER_THAN";
            case ERROR_ID_UNCLOSEDTAG:              return "Jenday Conure : UNCLOSED_TAG";
            case ERROR_ID_UNKNOWN_XML_IDENTIFIER:   return "Citron Cockatoo : UNKNOWN_XML_IDENTIFIER";
            case ERROR_ID_UNKNOWN_XML_ATTRIBUTE:    return "Hyacinth Macaw : UNKNOWN_XML_ATTRIBUTE";
            case ERROR_ID_NODE_DISORDER:            return "Dusky Pionus : NODE_DISORDER";

            default:
            case ERROR_ID_IDKWHAT:                  return "Murder_of_Crows_IDKWHAT";
        }
    }

    /* - END OF METHODS - */
}