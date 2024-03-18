/*

    What: Z-xtensible Markup Language File Stream Definition
    Who: Sarah Blackburn
    When: 19/02/22

*/


/*
    A StreamLine is an array of characters
    that make up each line of a file

*/
class StreamLine
{
    enum STREAMMODE
    {
        SM_NORMAL,
        SM_SELECTIVE,
        SM_OFF,
    };

    array<ModeDelimiter> Modes;

    int TrueLine;   // This is the actual line number in the file - for error output

    // Each character is stored as a string in the array - be nice to have actual chars
    array<string> Chars;

    int Length() { return Chars.Size(); }
    /*
        This was written when it was a possible bug
        that the Chars array might contain empty slots
        post-santization, therefore this was needed to
        compare array.Size() versus the full condition
        to determine if the bug was real.

        UsedLength is preserved as an option for an edge-case
        where the array may not be void of empty strings.
    */
    int UsedLength()
    {
        int tl = 0;
        for (int i = 0; i < Chars.Size(); i++)
        {
            if (Chars[i] != "")
                tl++;
        }

        return tl;
    }

    /*
        Works like any other Mid function,
        but works on the Chars array.
        Returns a string comprising the given length,
        starting from the given index.
    */
    string Mid(int at = 0, int len = 1)
    {
        string s = "";
        if (at >= 0 && len > 0 &&
            at < Length() && at + len <= Length())
        {
            for (int i = 0; i < len; i++)
                s.AppendFormat("%s", Chars[i + at]);
        }

        return s;
    }

    /*
        Returns the entire line as a single string
    */
    string FullLine()
    {
        string f = "";
        for (int i = 0; i < Length(); i++)
            f.AppendFormat("%s", Chars[i]);
        return f;
    }

    private bool LimitCheck(string c, bool eot)
    {
        for (int i = 0; i < Modes.Size(); i++)
        {
            if (eot && c == Modes[i].Encapsulator)
                return true;
            else if (!eot && c == Modes[i].Terminator)
                return true;
        }

        return false;
    }

    /*
        Line constructor

        Generally, this system is set to remove whitespace,
        however if that isn't desired for some reason, set mode to true.
    */
    StreamLine Init(string Line, int TrueLine, array<ModeDelimiter> Modes, STREAMMODE mode = SM_NORMAL)
    {
        // Put each character of the string into the array - normally remove whitespace
        bool limited = false,
            e = false,
            t = false;

        if (Modes)
            self.Modes.Copy(Modes);

        for (int i = 0; i < Line.Length(); i++)
        {
            int a = Line.ByteAt(i);
            // Is the mode normal? Check that the char is not whitespace, otherwise continue
            // The check looks odd, but the only extra character we are only ever letting through is the space
            if (mode == SM_NORMAL ? (a > 32 && a < 127) : (a >= 32 && a < 127))
            {
                // The mode is selective - anything between delimiters is included
                if (mode == SM_SELECTIVE)
                {
                    // Have we found the encapsulator?
                    if (!e)
                    {
                        e = LimitCheck(Line.Mid(i, 1), true);
                        // Check the remaining line and see if we encounter the terminator
                        // If not, do not set e
                        if (e)
                        {
                            bool be = false;
                            for (int j = i + 1; j < Line.Length(); j++)
                            {
                                if (LimitCheck(Line.Mid(j, 1), false))
                                    be = true;
                            }

                            if (!be)
                                e = false;
                        }
                    }
                    // Ok but we haven't found the terminator - look for it
                    else if (e && !t)
                        t = LimitCheck(Line.Mid(i, 1), false);

                    // Ok we found the encapsulator, but not the terminator, we just read everything
                    if (e && !t)
                        limited = true;
                    // That's the end of string that may need whitespace
                    else if (e && t)
                        limited = e = t = false;

                    // If the lexer is limited, let spaces through, otherwise do the normal whitespace check
                    if (limited ? (a >= 32 && a < 127) : (a > 32 && a < 127))
                    {
                        string c = Line.Mid(i, 1);
                        Chars.Push(c.MakeLower());
                    }
                }
                // It's either normal or off
                else
                {
                    string c = Line.Mid(i, 1);
                    Chars.Push(c.MakeLower());
                }
            }
        }

        self.TrueLine = TrueLine;

        if (self.Length() > 0)
            return self;
        else
            return null;
    }
}

/*
    Making the filestream aware of whitespace
    and default to removing it was wise.

    But spaces are valid characters, sometimes,
    in the XML, so handling of whitespace had
    to be expanded.  This class is just a utility
    class to allow the streamline to identify
    poritions of its line that should still contain
    spaces.
*/
class ModeDelimiter
{
    string Encapsulator, Terminator;
    ModeDelimiter Init(string Encapsulator, string Terminator)
    {
        self.Encapsulator = Encapsulator;
        self.Terminator = Terminator;
        return self;
    }
}


/*
    This is the actual "file stream" representation of the file.
    The string that is read from a file, called the "raw lump",
    is processed into an array structure of characters.

*/
class FileStream
{
    // The Stream member contains the textual information of each file
    array<StreamLine> Stream;
    // Lines() is a wrapper of Stream.Size(), generally used when wanting to know how many lines are in the stream
    int Lines() { return Stream.Size(); }

    int Line,           // Line represents which line of the file the reader is on
        Head,           // Head is ths character read head of the line
        LumpNumber,     // This is basically useless but interesting - this is the l value from Wads.ReadLump
        LumpHash;       // This value is calculated by hashing the contents of the lump and is used to eliminate duplicate reads

    string LumpName,    // LumpName and RawLump are saved for debugging purposes
           RawLump;

    /*
        Wrapper for resetting the stream
    */
    void Reset() { Line = Head = 0; }

    /*
        Wrapper for the two steps it takes to move to the next line
    */
    void NexLine()
    {
        Line++;
        Head = 0;
    }

    /*
        Returns the global index in the stream,
        which is the count of total characters
        read thus far.
    */
    int StreamIndex()
    {
        int si = 0;
        for (int i = 0; i < Line; i++)
            si += Stream[i].Length();
        return si + Head;
    }

    /*
        Returns the total count of characters in the stream
    */
    int StreamLength()
    {
        int sl = 0;
        for (int i = 0; i < Stream.Size(); i++)
            sl += Stream[i].Length();
        return sl;
    }

    /*
        Returns the length of the current line
    */
    int LineLength() { return Stream[Line].Length(); }

    /*
        Returns the length of the line in the stream at the given index
    */
    int LineLengthAt(int at) { return Stream[at].Length(); }

    /*
        https://bit.ly/3sqyUXj

        (Goes to StackOverflow)

        Its been a long while since I had a CS class
        that made me write my own hash function,
        so I just borrowed one from the link above.

        Kinda dirty, but it's used to create an ID hash
        for each file, to be checked during lump read,
        otherwise the reader makes duplicates for some
        odd reason.

        NOTE! The duplicate read problem is fixed, however
        I decided to leave this feature more for informational
        purposes now than anything; maybe a failsafe.

        NOTE NOTE!  This function is reused and tweaked
        throughout ZML - repeat credit to the author on SO!
    
    */
    static int GetLumpHash(string rl)
    {
        int a = 54059;
        int b = 76963;
        int c = 86969;
        int h = 37;
        for (int i = 0; i < rl.Length(); i++)
            h = (h * a) ^ (rl.ByteAt(i) * b);

        return h % c;
    }


    /*
        Returns the character on the given line at the given read index,
        or nothing if the given read index is beyond the line length.

    */
    string CharAt(int line, int head) { return head < Stream[line].Length() ? Stream[line].Chars[head] : ""; }

    /*
        Returns byte code of CharAt
    */
    int ByteAt(int line, int head) { return CharAt(line, head).ByteAt(0); }

    /*
        Stream constructor
    
    */
    FileStream Init(string RawLump, int LumpNumber, string LumpName, array<ModeDelimiter> Modes = null, int mode = 0)
    {
        self.Reset();
        self.LumpNumber = LumpNumber;
        self.LumpName = LumpName;
        self.LumpHash = FileStream.GetLumpHash(RawLump);
        self.RawLump = RawLump;

        // Break each line of the file into a StreamLine object
        string l = "";
        int tln = 1;    // This is the true line number, this is only for information during error output

        // Below is one rare instance where an interative loop may operate beyond array bounds.
        // The end of the RawLump does not contain an end-of-line marker.  Therefore the check for
        // such characters (new-line or eol) must account for the end of the lump string.
        for (int i = 0; i <= RawLump.Length(); i++)
        {
            string n = RawLump.Mid(i, 1);
            if (n != "\n" && n != "\0" && i < RawLump.Length())
                l.AppendFormat("%s", n);
            else if (l.Length() > 0)
            {
                StreamLine sl = new("StreamLine").Init(l, tln++, Modes, mode);
                if (sl)
                    Stream.Push(sl);
                l = "";
            }
        }
        //self.RawLumpOut();
        //self.StreamOut();
        return self;
    }

    /*
        Outputs the contents of the stream for debugging purposes
    */
    void StreamOut()
    {
        console.printf(string.Format("File Stream contains %d lines.  Contents:", Stream.Size()));
        for (int i = 0; i < Stream.Size(); i++)
        {
            string e = "";
            for (int j = 0; j < Stream[i].Length(); j++)
                e.AppendFormat("%s", Stream[i].Chars[j]);
            console.printf(string.format("Line #%d, length of %d, contents: %s", i, Stream[i].Length(), e));
        }
    }

    /*
        Wrapper for Outputing the RawLump itself.
    */
    void RawLumpOut(str_format sf = null, bool withrl = true, bool place = true)
    {
        if (sf)
        {
            if(withrl)
                console.printf(sf.FormatOut());
            else
            {
                if (place)
                    console.printf(string.Format("%s%s", sf.FormatOut(), RawLump));
                else
                    console.printf(string.Format("%s%s", RawLump, sf.FormatOut()));
            }
        }
        else
            console.printf(RawLump);
    }

    // Peek, return char on Line at Head
    string Peek() { return Stream[Line].Chars[Head]; }

    // PeekB, same as Peek, just returns the byte code
    int PeekB() { return Stream[Line].Chars[Head].ByteAt(0); }

    // PeekTo given length.  Moves Head and Line
    string PeekTo(int len = 1)
    {
        string s = "";

        if (!(Head >= 0 && Head < Stream[Line].Length()) ||
            !(Head + len <= Stream[Line].Length()))
        {
            Head = 0;
            Line++;
        }
        else if (!(len > 0 && len <= Stream[Line].Length()))
            return s;

        for (int i = 0; i < len; i++)
            s.AppendFormat("%s", Stream[Line].Chars[i + Head]);

        //console.printf(string.Format("\chPeekTo\cc, Line: %d, Head: %d, len: %d, Line Length: %d, Peek Contents: %s", Line, Head, len, Stream[Line].Length(), s));

        Head += len;
        return s;
    }

    /*
        Wrapper of PeekTo, but will also return the byte code
        It is assumed that the peek is for only one char
    */
    string, int PeekToB() 
    {
        string c = PeekTo();
        return c, c.ByteAt(0);
    }

    /*
        PeekEnd - a.k.a. Get End of Block

        What the end of block is can be defined.

        Returns the explicit line in the Stream to
        access next, but it does not directly set the
        Line member.  The parser should check the
        return before setting Line.

        PeekEnd does set Head.
    
    */
    int PeekEnd (string c, ZMLCharSet cs)
    {
        // Check each line, including this one
        int r = Head;
        for (int i = Line; i < Lines(); i++)
        {
            for (int j = r; j < Stream[i].Length(); j++)
            {
                //console.printf(string.format("Looking for character: %s -- Examining character, line %d, head %d, %s", c, i, j, CharAt(i, j)));
                if ((CharAt(i, j).ByteAt(0) == c.ByteAt(0)) &&      // Does the first character match?
                    (c.Length() > 1 ?                               // Do we need to look for more characters?
                        mul_charCheck(c, i, j) :                    // Yes, get the result of Multi-Char Check
                        true))                                      // No, skip this check, good that's a loop in a check
                {
                    // Is there more after?
                    if (j + c.Length() < Stream[i].Length())
                    {
                        //console.printf(string.format("\chPeekEnd\cc - There's more after the terminator, head at : %d, moving to %d, line %d", Head, j + c.Length(), i));
                        Head = j + c.Length();
                        return i;
                    }
                    // No, go to the next line.
                    else
                    {
                        //console.printf("\chPeekEnd\cc - Go to the next line");
                        Head = 0;
                        return i + 1;
                    }
                }
                else if (c.Length() == 1 && !IsAlphaNum(Stream[i].Chars[j].ByteAt(0)) && !IsCodeChar(Stream[i].Chars[j].ByteAt(0), cs))
                    return -1;
            }
            r = 0;
        }

        return -1; // We found nothing, which means something isn't closed, and now errors.
    }

    /*
        Multi-Char Check - lets PeekEnd look for more than two characters as a terminator sequence.  Yay!
    */
    private bool mul_charCheck(string c, int l, int h)
    {
        int q = 1;
        if (h + c.Length() - 1 < Stream[l].Length())
        {
            for (int i = 1; i < c.Length(); i++)
            {
                if (CharAt(l, h + i).ByteAt(0) == c.ByteAt(i))
                    q++;
            }
            return (q == c.Length());
        }
        else
            return false;
    }

    /*
        Returns boolean, checks if given string is a code character
    */
    bool IsCodeChar(int b, in ZMLCharSet cs)
    {
        for (int i = 0; i < cs.CodeChars.Size(); i++)
        {
            if (b == cs.CodeChars[i])
                return true;
        }

        return false;
    }

    /*
        Returns boolean, checks if the given string is alphanumeric
    */
    bool IsAlphaNum(int b)
    {
        if ((b > 47 && b < 58) || (b > 64 && b < 91) || (b > 96 && b < 123))
            return true;

        return false;
    }

    /* - END OF METHODS - */
}