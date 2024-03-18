/*

    What: Z-xtensible Markup Language XML Token Definition
    Who: Sarah Blackburn
    When: 16/04/22

*/

class XMLToken
{
    enum W_TOKEN
    {
        WORD_ROOT,
        WORD_NODE,
        WORD_ATTRIBUTE,
        WORD_TERMINATE,
        WORD_NONE,
    };
    W_TOKEN t;

    int tagLine,
        tagStart,
        tagLength,
        dataLine,
        dataStart,
        dataLength;

    static int StringToToken(string e)
    {
        return WORD_NONE;
    }

    static string TokenToString(int t)
    {
        switch (t)
        {
            case WORD_ROOT: return "WORD_ROOT";
            case WORD_NODE: return "WORD_NODE";
            case WORD_ATTRIBUTE: return "WORD_ATTRIBUTE";
            case WORD_TERMINATE: return "WORD_TERMINATE";
            default: return "WORD_NONE";
        }
    }

    XMLToken Init(int t, int tagLine, int tagStart = 0, int tagLength = 0,
        int dataLine = 0, int dataStart = 0, int dataLength = 0)
    {
        self.t = t;
        self.tagLine = tagLine;
        self.tagStart = tagStart;
        self.tagLength = tagLength;
        self.dataLine = dataLine;
        self.dataStart = dataStart;
        self.dataLength = dataLength;
        return self;
    }
}