/*
    What : ZML Parser Def Token Definition
    Who : Sarah Blackburn
    When : 27/03/2022

*/


class DefToken
{
    enum W_TOKEN
    {
        WORD_TAG,
        WORD_ATTRIBUTE,
        WORD_NAME,
        WORD_TYPE,
        WORD_TERMINATE,
        WORD_NONE,
    };

    W_TOKEN t;
    int line,
        start,
        length; 

    static int StringToToken(string e)
    {
        if (e ~== "tag")
            return WORD_TAG;
        if (e ~== "attribute")
            return WORD_ATTRIBUTE;
        if (e ~== ";" || e ~== "}")
            return WORD_TERMINATE;

        return WORD_NONE;
    }

    static string TokenToString(int t)
    {
        switch (t)
        {
            case WORD_TAG: return "WORD_TAG";
            case WORD_ATTRIBUTE: return "WORD_ATTRIBUTE";
            case WORD_NAME: return "WORD_NAME";
            case WORD_TYPE: return "WORD_TYPE";
            case WORD_TERMINATE: return "WORD_TERMINATE";
            default: return "WORD_NONE";
        }
    }

    DefToken Init(int t, int line, int start = 0 , int length = 0)
    {
        self.t = t;
        self.line = line;
        self.start = start;
        self.length = length;
        return self;
    }
}