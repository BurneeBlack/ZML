/*
    What : ZML Tag Definition (ZMLDEFS) Parser
    Who : Sarah Blackburn
    When : 19/03/2022

*/


class ZMLTagParser
{
    const CHAR_ID_DOUBLEQUOTE = 34;
    const CHAR_ID_ASTERISK = 42;
    const CHAR_ID_COMMA = 44;
    const CHAR_ID_BACKSLASH = 47;
    const CHAR_ID_SEMICOLON = 59;
    const CHAR_ID_UNDERSCORE = 95;
    const CHAR_ID_OPENBRACE = 123;
    const CHAR_ID_CLOSEBRACE = 125;

    ZMLCharset DefCharSet;
    private void makeCharset()
    {
        DefCharset.CodeChars.Push(CHAR_ID_DOUBLEQUOTE);
        DefCharset.CodeChars.Push(CHAR_ID_ASTERISK);
        DefCharset.CodeChars.Push(CHAR_ID_COMMA);
        DefCharset.CodeChars.Push(CHAR_ID_BACKSLASH);
        DefCharset.CodeChars.Push(CHAR_ID_SEMICOLON);
        DefCharset.CodeChars.Push(CHAR_ID_UNDERSCORE);
        DefCharset.CodeChars.Push(CHAR_ID_OPENBRACE);
        DefCharset.CodeChars.Push(CHAR_ID_CLOSEBRACE);
    }

    // Contents of each file
    array<FileStream> Streams;

    // Counts how many files failed to parse
    int ParseErrorCount;
    array<StreamError> ParseErrorList;

    // This is the final result, a list of xml tags!
    array<ZMLTag> TagList;

    ZMLTagParser Init()
    {
        // Initialize internals
        makeCharset();
        ParseErrorCount = 0;
        int streamSize = Generate_Streams();
        for (int i = 0; i < streamSize; i++)
        {
            array<DefToken> parseList;
            // Sanitize Comments, 
            // then check continuity (check for most of the basic errors),
            // lastly generate token list - this is what to do and where in the stream
            if (Sanitize_StreamComments(Streams[i]) ? 
                (Check_StreamContinuity(Streams[i]) ? 
                    Tokenize(Streams[i], parseList) : 
                    false) : 
                false)
                // All of that worked?  Ok
                Parse(Streams[i], parseList);
            else
                ParseErrorCount++;
        }
        
        // Error output
        if (ParseErrorCount > 0)
        {
            console.printf(string.Format("\n\t\t\ciZML failed to parse \cg%d \citag definition lumps!\n\t\t\t\t\cc- This means ZML encountered a problem with the file%s and stopped trying to create usable data from %s. Reported errors need fixed.\n\n", ParseErrorCount, (ParseErrorCount > 1 ? "s" : ""), (ParseErrorCount > 1 ? "them" : "it")));

            for (int i = 0; i < ParseErrorList.Size(); i++)
            {
                StreamError error = ParseErrorList[i];
                console.printf(string.Format("\t\t\cgZML ERROR! Code: \cx%s_(%d) \cg- Lump: #\ci%d\cg, Lump Hash: \ci%d\cg, Message: \ci%s\cg\n\t\t\t - Contents of Lexer: \ci%s \cg- Last known valid data started at line: #\cii:%d\cg(\cyf:%d\cg)!\n\t\t\t - Line contents: \cc%s\n\n",
                    error.CodeString, error.CodeId, error.LumpNumber, error.LumpHash, error.Message, error.StreamBufferContents, error.InternalLine, error.FileLine, error.FullLine));
            }
        }
        // Nevermind, yay!  We win!
        else
            console.printf(string.format("\n\t\t\cyZML successfully parsed \cx%d \cyZMLDEFS lumps into \cx%d \cyZML tags!\n\n", Streams.Size(), TagList.Size()));

        return self;
    }

    // Checks the array to see if any streams have the same hash
    private bool, int HaveStream(int h)
    {
        for (int i = 0; i < Streams.Size(); i++)
        {
            if (Streams[i].LumpHash == h)
                return true, i;
        }

        return false, -1;
    }

    /* 
        Reads each def lump into the Streams array
    */
    private int Generate_Streams(int l = 0)
    {
        while ((l = Wads.FindLump("zmldefs", l)) != -1)
        {
            // Read the lump into a string - there should be the base ZMLDEFS in the ZML package
            string rl = Wads.ReadLump(l);
            // HaveStream returns bool, int
            bool hs;
            int ds;
            // Check if the lump has already been read - hs will be false if not, and ds will be the index in the file stream array if true
            [hs, ds] = HaveStream(FileStream.GetLumpHash(rl));
            if (!hs)
                Streams.Push(new("FileStream").Init(rl, l, Wads.GetLumpFullName(l)));
            else
                console.printf(string.Format("\t\t\ciZML Warning! \ccNo big deal, but tried to read the same lump twice! Original lump # \ci%d\cc, duplicate lump # \ci%d", Streams[ds].LumpNumber, l));

            l++;
        }

        console.printf(string.Format("\t\t\cdZML successfully read \cy%d \cdtag definition lumps into file streams!\n\t\t\t\t\cc- This means the ZMLDEFS files are in a parse-able format, it does not mean they are valid.\n\n", Streams.Size()));
        return Streams.Size();
    }

    /*
        Stream creation, by default, removes whitespace,
        but does not remove comments.  So each stream needs
        fixed before checking continuity.

    */
    private bool Sanitize_StreamComments(in out FileStream file)
    {
        string e = "";
        while (file.StreamIndex() < file.StreamLength())
        {
            e.AppendFormat("%s", file.PeekTo());
            if (e.ByteAt(0) == CHAR_ID_BACKSLASH)
            {
                // Block comment
                if (file.PeekB() == CHAR_ID_ASTERISK)
                {
                    // Go back one char to  pick up the backslach
                    int ws = file.Head - 1;
                    // Find where the end of the comment is
                    int nextLine = file.PeekEnd("*/", DefCharSet);
                    // Found it
                    if (nextLine != -1)
                    {
                        // Delete the lines containing the comment
                        for (int i = file.Line; i <= nextLine; i++)
                        {
                            // The loop goes to nexLine, but if the stream head is 0,
                            // then there's no more comment to remove, so break.
                            if (i == nextLine && file.Head == 0)
                                break;

                            // Establish how many chars to delete
                            int dt;
                            // If at the end of the comment, go to wherever the stream head is
                            if (i == nextLine)
                                dt = file.Head;
                            // Otherwise go the entire line length
                            else
                                dt = file.LineLengthAt(i);

                            // Delete the chars in the line
                            for (int j = ws; j < dt; j++)
                                file.Stream[i].Chars.Delete(ws > 0 ? ws : 0);

                            // Fix the array
                            file.Stream[i].Chars.ShrinkToFit();

                            // This variable allows the loop to delete the beginning of comments
                            // that are on lines with valid code before the comment.  So after the
                            // first line of the comment, this variable must be reset to 0 to delete
                            // entire lines.
                            ws = 0;
                        }

                        // PeekEnd returns the explicit line to move to, but does not set it.
                        file.Line = nextLine;
                    }
                    else
                    {
                        /* Throw open comment error */
                        ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_OPENCOMMENT, 
                            file.LumpNumber, 
                            file.LumpHash, 
                            file.LumpName,
                            "UNCLOSED BLOCK COMMENT!", 
                            e, 
                            file.Line, 
                            file.Stream[file.Line].TrueLine, 
                            file.Stream[file.Line].FullLine()));
                        return false;    
                    }
                }
                // Line comment
                else if (file.PeekB() == CHAR_ID_BACKSLASH)
                {
                    // MUCH simpler, line comments just remove anything after the backslashes
                    // Because this is messing with the line length, the LineLength function
                    // becomes indeterminate, so the original length gets stored and used instead.
                    // It APPEARS that array.Delete deletes whatever is at the given index, moves everything
                    // after to the left, but does not resize the array, thus hammering at one index,
                    // for the total orginal length of the array, is perfectly safe.
                    // This also ensures partial and entire lines are handled.
                    int dt = file.LineLength();
                    // Delete the chars in the line - basically same thing as block comments
                    for (int i = file.Head - 1; i < dt; i++)
                        file.Stream[file.Line].Chars.Delete(file.Head - 1);
                    // Fix the array
                    file.Stream[file.Line].Chars.ShrinkToFit();
                    // Go to the next line
                    file.NexLine();
                }
                else
                {
                    /* Throw unexpected character error */
                    ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_UNEXPECTEDCODE, 
                        file.LumpNumber, 
                        file.LumpHash, 
                        file.LumpName,
                        "UNEXPECTED CHARACTER READ!", 
                        e, 
                        file.Line, 
                        file.Stream[file.Line].TrueLine, 
                        file.Stream[file.Line].FullLine()));
                    return false;
                }
            }

            // Last step, clear the buffer, we need to reach each character individually.
            e = "";
        }

        // Remove empty lines from the stream
        for (int i = 0; i < file.Lines(); i++)
        {
            if (file.LineLengthAt(i) == 0)
                file.Stream.Delete(i--);
        }
        file.Stream.ShrinkToFit();

        // Reset the stream
        file.Reset();
        //file.StreamOut();
        return true;
    }

    /*
        Checks each file for continuity - this means quotes are closed, braces are closed,etc.

        This function is a clusterfuck of just jfc...facepalm.
        *Head hits keyboard.
    */
    private bool Check_StreamContinuity(in out FileStream file)
    {
        int qc = 0,     // Quote count
            cc = 0,     // Comma count
            obc = 0,    // Open brace count
            cbc = 0;    // Close brace count
        // Read entire stream
        while (file.StreamIndex() < file.StreamLength())
        {
            string c;
            int b;
            [c, b] = file.PeekToB();
            // Check it's a valid char
            if (file.IsCodeChar(b, DefCharSet))
            {
                // Yes, what is it? Increment that counter.
                switch (b)
                {
                    case CHAR_ID_DOUBLEQUOTE: qc++; break;
                    case CHAR_ID_COMMA: cc++; break;
                    case CHAR_ID_OPENBRACE: obc++; break;
                    case CHAR_ID_CLOSEBRACE: cbc++; break;
                }
            }
            // No, ok, it's not an underscore right, that's valid too, is it alpha-numeric?
            else if (b != CHAR_ID_UNDERSCORE && !file.IsAlphaNum(b))
            {
                // Nope, add invalid char to error list 
                ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_INVALIDCHAR, 
                    file.LumpNumber, 
                    file.LumpHash, 
                    file.LumpName,
                    "INVALID CHARACTER DETECTED!", 
                    c, 
                    file.Line, 
                    file.Stream[file.Line].TrueLine, 
                    file.Stream[file.Line].FullLine()));
                return false;
            }
        }

        // Assuming success the stream needs reset
        file.Reset();

        // Quote count - should be 2 for each word, thus remainder should be 0
        if (qc % 2 != 0)
        { 
            // Go line by line
            for (int i = 0; i < file.Lines(); i++)
            {
                int lqc = 0;
                // Read each char and count the number of quotes encountered
                for (int j = 0; j < file.LineLengthAt(i); j++)
                {
                    if (file.ByteAt(i, j) == CHAR_ID_DOUBLEQUOTE)
                        lqc++;
                }

                // If the number is more than zero and not four, that's the problem line.
                if (lqc > 0 && lqc != 4)
                {
                    // Add missing quote to error list
                    ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_OPENSTRING, 
                        file.LumpNumber, 
                        file.LumpHash, 
                        file.LumpName,
                        "UNCLOSED STRING FOUND!", 
                        "N/A", 
                        i, 
                        file.Stream[i].TrueLine, 
                        file.Stream[i].FullLine()));
                    return false;
                }
            }
        }

        // Comma count - should be 1 for every 4 quotes
        if (cc != qc / 4)
        { 
            // Oh boy! Go line by line again
            for (int i = 0; i < file.Lines(); i++)
            {
                bool bc = false;
                // Read each char again!
                for (int j = 0; j < file.LineLengthAt(i); j++)
                {
                    // Did we get a quotation?
                    if (file.ByteAt(i, j) == CHAR_ID_DOUBLEQUOTE)
                    {
                        // Crap!  Ok, read the line again and see if there's a comma
                        for (int k = 0; k < file.LineLengthAt(i); k++)
                        {
                            // Omg there is, get out of this loop now!
                            if (file.ByteAt(i, k) == CHAR_ID_COMMA)
                            {
                                bc = true;
                                break;
                            }
                        }
                        // There was not, that would be the problem line
                        if (!bc)
                        {
                            // Add missing comma to error list 
                            ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_MISSINGCOMMA, 
                                file.LumpNumber, 
                                file.LumpHash, 
                                file.LumpName,
                                "COMMA (,) MISSING BETWEEN NAME AND TYPE OF ELEMENT!", 
                                "N/A", 
                                i, 
                                file.Stream[i].TrueLine, 
                                file.Stream[i].FullLine()));
                            return false;
                        }
                    }
                }
            }
        }

        // Open brace count - should be equal to close brace count
        if (obc < cbc)
        {
            int lobc = 0,
                lcbc = 0;
            // Go line by line, but in reverse!
            for (int i = file.Lines() - 1; i >= 0; i--)
            {
                // Ok read each char from left to right like normal
                for (int j = 0; j < file.LineLengthAt(i); j++)
                {
                    // Is it a close brace?  Increment the counter
                    if (file.ByteAt(i, j) == CHAR_ID_CLOSEBRACE)
                        lcbc++;
                    // No, ok the close brace counter has counted braces and we've encountered an open brace
                    else if (lcbc > 0 && file.ByteAt(i, j) == CHAR_ID_OPENBRACE)
                    {
                        // Start over, from where we're at, so this starts the line loop again
                        for (int k = i; k >= 0; k--)
                        {
                            int mj = k == i ? j : 0;
                            // Read the chars in the line
                            for (int m = mj; m < file.LineLengthAt(k); m++)
                            {
                                // If is an open brace, increment the counter
                                if (file.ByteAt(k, m) == CHAR_ID_OPENBRACE)
                                    lobc++;
                                // No, its a close brace, which should be the next set of braces, so check the count.
                                // If open brace count is less than close brace count, this is our error line.
                                // Good god the getting here.
                                else if (file.ByteAt(k,m) == CHAR_ID_CLOSEBRACE || (k == 0 && lobc < lcbc))
                                {
                                    // Add missing open brace to error list
                                    ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_MISSINGOPENBRACE, 
                                        file.LumpNumber, 
                                        file.LumpHash, 
                                        file.LumpName,
                                        "OPEN BRACE ( { ) MISSING!", 
                                        "N/A", 
                                        k, 
                                        file.Stream[k].TrueLine, 
                                        file.Stream[k].FullLine()));
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
        }
        // Close brace count - should be equal to open brace count
        else if (cbc < obc)
        {
            int lobc = 0,
                lcbc = 0;
            // Go line by line, normally this time
            for (int i = 0; i < file.Lines(); i++)
            {
                // Ok read each char from left to right like normal
                for (int j = 0; j < file.LineLengthAt(i); j++)
                {
                    // Is it a open brace?  Increment the counter
                    if (file.ByteAt(i, j) == CHAR_ID_OPENBRACE)
                        lobc++;
                    // No, ok the open brace counter has counted braces and we've encountered a close brace
                    else if (lobc > 0 && file.ByteAt(i, j) == CHAR_ID_CLOSEBRACE)
                    {
                        // Start over, from where we're at, so this starts the line loop again
                        for (int k = i; k < file.Lines(); k++)
                        {
                            int mj = k == i ? j : 0;
                            // Read the chars in the line
                            for (int m = mj; m < file.LineLengthAt(k); m++)
                            {
                                // If is an open brace, increment the counter
                                if (file.ByteAt(k, m) == CHAR_ID_CLOSEBRACE)
                                    lcbc++;
                                // No, its an open brace, which should be the next set of braces, so check the count.
                                // If close brace count is less than open brace count, this is our error line.
                                // Good god the getting here...twice.
                                else if (file.ByteAt(k,m) == CHAR_ID_OPENBRACE || (k == file.Lines() -1 && lcbc < lobc))
                                {
                                    // Add missing close brace to error list
                                    ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_MISSINGCLOSEBRACE, 
                                        file.LumpNumber, 
                                        file.LumpHash, 
                                        file.LumpName,
                                        "CLOSE BRACE ( } ) MISSING!", 
                                        "N/A", 
                                        k, 
                                        file.Stream[k].TrueLine, 
                                        file.Stream[k].FullLine()));
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Semicolon check - read each line, like normal
        for (int i = 0; i < file.Lines(); i++)
        {
            // Read each char, like normal
            for (int j = 0; j < file.LineLengthAt(i); j++)
            {
                // The line has to have a quote in it, 
                // then the end of the line should either 
                // be a semicolon or and open brace;
                // I allow for both brace styles this way.
                if (file.ByteAt(i, j) == CHAR_ID_DOUBLEQUOTE &&
                    (file.ByteAt(i, file.LineLengthAt(i) - 1) != CHAR_ID_SEMICOLON ? 
                        file.ByteAt(i, file.LineLengthAt(i) - 1) != CHAR_ID_OPENBRACE :
                        false) &&
                    file.ByteAt(i + 1, 0) != CHAR_ID_OPENBRACE)
                {
                    // Add missing semicolon to error list
                    ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_MISSINGEOB, 
                        file.LumpNumber, 
                        file.LumpHash, 
                        file.LumpName,
                        "END OF BLOCK ( ; ) MISSING!", 
                        "N/A", 
                        i, 
                        file.Stream[i].TrueLine, 
                        file.Stream[i].FullLine()));
                    return false;
                }
            }
        }

        // Assuming none of the above fails and returns false,
        return true;
    }

    /*
        This creates the token list from the file.
        What this means, is tokens are treated as
        instructions.
    */
    private bool Tokenize(in out FileStream file, in out array<DefToken> parseList)
    {
        // The buffer for the loop
        string e = "";

        // Set up a standard EOF check
        while (file.StreamIndex() < file.StreamLength())
        {
            // In this case make an internal buffer so we can check whats inside of it.
            // This buffer will only have one character
            string et = file.PeekTo();

            // Now the basic check is, does the main buffer have something in it
            // and does the temp buffer contain a code char?
            // But, if we've got a semicolon or close brace, those result in tokens.
            if (e.Length() > 0 && file.IsCodeChar(et.ByteAt(0), DefCharSet) &&
                et.ByteAt(0) != CHAR_ID_SEMICOLON && et.ByteAt(0) != CHAR_ID_CLOSEBRACE)
            {
                ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_UNKNOWNIDENTIFIER,
                    file.LumpNumber,
                    file.LumpHash,
                    file.LumpName,
                    "UNKNOWN IDENTIFIER DETECTED!",
                    string.Format("Temp Buffer: %s, Buffer: %s", et, e),
                    file.Line,
                    file.Stream[file.Line].TrueLine,
                    file.Stream[file.Line].FullLine()));
                return false;
            }
            else
            {
                // If the temp buffer contains alpha-numeric characters, or semicolon or close brace, put it in the main buffer
                if (file.IsAlphaNum(et.ByteAt(0)) || et.ByteAt(0) == CHAR_ID_SEMICOLON || et.ByteAt(0) == CHAR_ID_CLOSEBRACE)
                    e.AppendFormat("%s", et);

                // Precheck the token result, otherwise the buffer needs preserved
                if (DefToken.StringToToken(e) != DefToken.WORD_NONE)
                {
                    // Turn the buffer into a token for list storage
                    switch (DefToken.StringToToken(e))
                    {
                        case DefToken.WORD_TAG:
                            //console.printf("The word is tag!");
                            // Push a tag token
                            //PushToken(DefToken.WORD_TAG, file.Line);
                            parseList.Push(new("DefToken").Init(DefToken.WORD_TAG, file.Line));
                            // These are indices for the name and type of the tag
                            int tns = 0, tne = 0,
                                tts = 0, tte = 0;
                            //console.printf(string.format("Line used length is: %d, zscript length: %d, full line: %s", file.Stream[file.Line].UsedLength(), file.LineLength(), file.Stream[file.Line].FullLine()));
                            // Read the rest of the line to find the name and type
                            for (int i = file.Head; i < file.LineLength(); i++)
                            {
                                // If we encountered a quote, then based on bool checks of the indices we can set them
                                if (file.ByteAt(file.Line, i) == CHAR_ID_DOUBLEQUOTE)
                                {
                                    if (!tns) // Name start
                                        tns = i + 1;
                                    else if (tns && !tne) // Name end
                                        tne = i - 1;
                                    else if (tns && tne && !tts) // Type start
                                        tts = i + 1;
                                    else if (tns && tne && tts && !tte) // Type end
                                        tte = i - 1;
                                }
                            }

                            // Got the indices so push the tokens
                            if (tns && tne && tts && tte)
                            {
                                parseList.Push(new("DefToken").Init(DefToken.WORD_NAME, file.Line, tns, tne - tns + 1)); // for example 5-0=5, but that's 6 chars, so add 1 since it wants to know start index and length
                                parseList.Push(new("DefToken").Init(DefToken.WORD_TYPE, file.Line, tts, tte - tts + 1));
                            }

                            //console.printf(string.format("Setting head to %d, was at %d, tag name start: %d, tag name end: %d, tag type start: %d, tag type end: %d", tte + 1, file.Head, tns, tne, tts, tte));
                            // Move the head to the double quote at the end of the type
                            file.Head = tte + 1;
                            break;

                        case DefToken.WORD_ATTRIBUTE:
                            //console.printf("Got an attribute list!");
                            // Read the next lines until we find a close brace
                            for (int i = file.Line; i < file.Lines(); i++)
                            {
                                // Indices for the name and type of each attribute
                                int ans = 0, ane = 0,
                                    ats = 0, ate = 0,
                                    th, hp;
                                // Handling termination is done by the termination case, so we just check for it here
                                bool closeList = false,
                                    attributeStored = false;

                                // Of course there's the usual pick up where we are in the stream,
                                // then once we jump lines we need to set head to 0
                                if (i == file.Line)
                                    th = file.Head;
                                else
                                    th = 0;

                                // Read the line
                                for (int j = th; j < file.LineLengthAt(i); j++)
                                {
                                    // Same magic as with tags
                                    if (file.ByteAt(i, j) == CHAR_ID_DOUBLEQUOTE)
                                    {
                                        if (!ans) // Name start
                                            ans = j + 1;
                                        else if (ans && !ane) // Name end
                                            ane = j - 1;
                                        else if (ans && ane && !ats) // Type start
                                            ats = j + 1;
                                        else if (ans && ane && ats && !ate) // Type end
                                            ate = j - 1;
                                    }
                                    // But once we hit a semicolon we do need to store a termination tag
                                    else if (file.ByteAt(i, j) == CHAR_ID_SEMICOLON)
                                        parseList.Push(new("DefToken").Init(DefToken.WORD_TERMINATE, i));
                                    // Once we hit the end of the list we need to flag as such and preserve the internal head
                                    else if (file.ByteAt(i, j) == CHAR_ID_CLOSEBRACE)
                                    {
                                        closeList = true;
                                        hp = j;
                                    }

                                    // Did we get all the indices?  Ok store tokens
                                    if (ans && ane && ats && ate && !attributeStored)
                                    {
                                        // Push an attribute token, then the name and type
                                        parseList.Push(new("DefToken").Init(DefToken.WORD_ATTRIBUTE, file.Line));
                                        parseList.Push(new("DefToken").Init(DefToken.WORD_NAME, i, ans, ane - ans + 1));
                                        parseList.Push(new("DefToken").Init(DefToken.WORD_TYPE, i, ats, ate - ats + 1));
                                        attributeStored = true;
                                    }
                                }

                                // Got the close brace, so set line and head so it's picked up next loop
                                if (closeList)
                                {
                                    file.Line = i;
                                    file.Head = hp;
                                    break;
                                }
                            }
                            break;
                    }

                    // Got a valid token so purge the buffer
                    e = "";
                }
            }
        }

        file.Reset();
        //TokenListOut(file, parseList);
        return true;
    }

    /*
        Outputs the contents of the Token List for debugging purposes
    */
    private void TokenListOut(in FileStream file, in array<DefToken> tokens)
    {
        console.printf(string.Format("Token List contains %d tokens.  Contents:", tokens.Size()));
        for (int i = 0; i < tokens.Size(); i++)
            console.printf(string.format("Token #%d, word is: #:%d(s:%s), found on line: i:%d(f:%d), starts at: %d, length of: %d, resultant: %s", 
                i, tokens[i].t, DefToken.TokenToString(tokens[i].t), tokens[i].line, file.Stream[tokens[i].line].TrueLine, tokens[i].start, tokens[i].length,
                tokens[i].length > 0 ? file.Stream[tokens[i].line].Mid(tokens[i].start, tokens[i].length) : "empty"));
    }

    /*
        Turns the token list into xml tags
        The "getting here" tho
    */
    private void Parse(in FileStream file, in array<DefToken> parseList)
    {
        // Check that the list has something in it
        if (parseList.Size() > 0)
        {
            // One last pre-parse check that can end this - invalid types
            // This can be checked from the parse list
            for (int i = 0; i < parseList.Size(); i++)
            {
                if (parseList[i].t == DefToken.WORD_TYPE)
                {
                    int t = ZMLElement.GetType(file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length));
                    if (t == ZMLElement.t_unknown)
                    {
                        ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_INVALIDTYPE,
                            file.LumpNumber,
                            file.LumpHash,
                            file.LumpName,
                            "INVALID TYPE ENUMERATION DETECTED!",
                            file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length),
                            i,
                            file.Stream[i].TrueLine,
                            file.Stream[i].FullLine()));
                        ParseErrorCount++;          
                        return;      
                    }            
                }
            }

            // The only birds in the flock!  We have to differentiate between attributes and tags
            bool openTag = false,
                openAttribute = false;
            // Read through the token list
            for (int i = 0; i < parseList.Size(); i++)
            {
                // Should have an error free time from here!
                switch(parseList[i].t)
                {
                    // Create a new tag
                    case DefToken.WORD_TAG:
                        TagList.Push(new("ZMLTag").Init("", ""));
                        openTag = true;
                        break;
                    // Give that tag an attribute
                    case DefToken.WORD_ATTRIBUTE:
                        TagList[TagList.Size() - 1].Attributes.Push(new("ZMLElement").Init("", ""));
                        openAttribute = true;
                        break;
                    // Assign a name to something
                    case DefToken.WORD_NAME:
                        if (openTag && !openAttribute)
                            TagList[TagList.Size() - 1].Name = file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length);
                        else if (openAttribute)
                            TagList[TagList.Size() - 1].Attributes[TagList[TagList.Size() - 1].Attributes.Size() - 1].Name = file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length);
                        break;
                    // Assign a type to something - this is protected by the above check
                    case DefToken.WORD_TYPE:
                        if (openTag && !openAttribute)
                            TagList[TagList.Size() - 1].Type = ZMLElement.GetType(file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length));
                        else if (openAttribute)
                            TagList[TagList.Size() - 1].Attributes[TagList[TagList.Size() - 1].Attributes.Size() - 1].Type = ZMLElement.GetType(file.Stream[parseList[i].line].Mid(parseList[i].start, parseList[i].length));
                        break;
                    // End whatever, here it's just so we don't assign to the wrong thing
                    case DefToken.WORD_TERMINATE:
                        if (openTag && !openAttribute)
                            openTag = false;
                        else if (openAttribute)
                            openAttribute = false;
                }
            }
        }
        // Uh, probably got here because of an empty file - idk what else would have let us get here.
        else
        {
            ParseErrorList.Push(new("StreamError").Init(StreamError.ERROR_ID_EMPTYFILE,
                file.LumpNumber,
                file.LumpHash,
                file.LumpName,
                "NOTHING TO PARSE, FILE IS EMPTY?!\n\t \ci- Please remove file from load order if everything is commented out,\n\t - you wasted A LOT of processing time getting to this error, thank you.",
                "N/A",
                -1,
                -1,
                "N/A"));
            ParseErrorCount++;
        }

        //TagListOut();
    }

    /*
        Outputs the tag list for debugging purposes
    */
    private void TagListOut()
    {
        for (int i = 0; i < TagList.Size(); i++)
        {
            string al = string.Format(" -- Tag contains (%d) attributes: ", TagList[i].Attributes.Size());
            for (int j = 0; j < TagList[i].Attributes.Size(); j++)
                al.AppendFormat("%s (type:%d), ", TagList[i].Attributes[j].Name, TagList[i].Attributes[j].Type);

            console.printf(string.Format("Tag is named (type%d): %s%s", TagList[i].Type, TagList[i].Name, TagList[i].Attributes.Size() > 0 ? al : ""));
        }
    }

    /* - END OF METHODS - */
}