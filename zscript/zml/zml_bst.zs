/*

    What: Z-xtensible Markup Language Binary Search Tree Definition
    Who: Sarah Blackburn
    When: 24/04/22

    It actually occurs to me that this file is one of the most important
    in the whole thing, as these classes define the entirety of the
    XML tree, thus I should probably document.

*/

/*
    Every node in the tree is a ZMLNode.
    The node IS the binary tree, meaning
    each node can become its own tree.

*/
class ZMLNode
{
    string FileName,    // Translation units end up being called "zml", but everything else will be the definition file name
        Name,           // The tag name
        Data;           // What the tag contains - API or user functions will just have to cast.

    int Weight,         // Internal value governing place in the tree;
        Seed;           // This is a random value generated when the parser runs, it's used in hashing to help "randomness"

    // Descendent Tree Nodes
    ZMLNode Children,   // If a node is contained in this one, it will be a child
        LeftSibling,    // If a node is contained alongside this one, it will be a sibling
        RightSibling;

    // Attributes are garbage and should not be a thing
    // They honestly add a bunch of extra string witchcraft to an already nicely woven spell.
    array<ZMLAttribute> Attributes;

    /*
        Takes a string and an integer and makes
        a mess of an integer of it.
    */
    int Hash(string d, int r)
    {
        int a = 54059;
        int b = 76963;
        int c = 86969;
        int h = 37;
        for (int i = 0; i < d.Length(); i++)
            h = (h * a) ^ (d.ByteAt(i) * b);

        return h * r % c;
    }

    /*
        Returns the Weight of the node
        by calling Hash and formatting the string
    */
    private int InsertWeight(string f, string n, string d) { return Hash(string.Format("%sz%sm%sl", f, n, d), Seed); }

    /*
        Node constructor
    */
    ZMLNode Init(int Seed, string FileName, string Name, string Data)
    {
        self.FileName = FileName;
        self.Name = Name;
        self.Data = Data;
        int h = Hash(string.Format("%sz%sm%sl", FileName, Name, Data), Seed);
        if (h < 0)
            self.Weight = h * -1;
        else
            self.Weight = h;
        self.Seed = Seed;
        Children = LeftSibling = RightSibling = null;
        return self;
    }

    /*
        Inserts a sibling node
    */
    ZMLNode InsertNode(in out ZMLNode Tree, int Seed, string FileName, string Name, string Data)
    {
        if (!Tree)
        {
            Tree = new("ZMLNode").Init(Seed, FileName, Name, Data);
            return Tree;
        }
        else if (Tree.Weight > InsertWeight(FileName, Name, Data))
            return InsertNode(Tree.LeftSibling, Seed, FileName, Name, Data);
        else
            return InsertNode(Tree.RightSibling, Seed, FileName, Name, Data);
    }

    /*
        Eliminates any node attached to the given filename
    */
    void Delete(ZMLNode Tree, string FileName)
    {
        if (Tree.Weight > InsertWeight(FileName, Name, Data))
            Delete(Tree.LeftSibling, FileName);
        else if (Tree.Weight < InsertWeight(FileName, Name, Data))
            Delete(Tree.RightSibling, FileName);
        else
            DeleteNode(Tree);
    }

    /*
        Does the deleting
    */
    private void DeleteNode(in out ZMLNode Tree)
    {
        string d;
        ZMLNode tn = Tree;
        if (!Tree.LeftSibling)
            Tree = Tree.RightSibling;
        else if (!Tree.RightSibling)
            Tree = Tree.LeftSibling;
        else
        {
            GetPredecessor(Tree.LeftSibling);
            Tree.Data = d;
            Delete(Tree.LeftSibling, Tree.LeftSibling.FileName);
        }
    }

    /*
        Utility for deletion
    */
    private string GetPredecessor(in out ZMLNode Tree)
    {
        while (Tree.RightSibling)
            Tree = Tree.RightSibling;
        return Tree.Data;
    }

    /*
        Debug function for printing the node contents.
        Best thing is to call this on the tree root
        so it's executed on the whole tree.
    */
    clearscope void NodeOut()
    {
        console.printf(string.format("ZMLNode, Name: %s, from file: %s, contains data: %s\n\tnode weight: %d\n\tnode has children: %s, root child name: %s\n\tnode has left sibling: %s, left sibling name: %s\n\tnode has right sibling: %s, right sibling name: %s\n\n",
            Name, FileName, Data, Weight,
            Children ? string.Format("yes (root weight: %d)", Children.Weight) : "no",
            Children ? Children.Name : "N/A",
            LeftSibling ? string.Format("yes (root weight: %d)", LeftSibling.Weight) : "no",
            LeftSibling ? LeftSibling.Name : "N/A",
            RightSibling ? string.Format("yes (root weight: %d)", RightSibling.Weight) : "no",
            RightSibling ? RightSibling.Name : "N/A"));

        for (int i = 0; i < Attributes.Size(); i++)
            console.printf(string.Format("Node, %s, contains attribute named: %s, with value: %s", Name, Attributes[i].Name, Attributes[i].Value));

        if (Children)
            Children.NodeOut();
        if (LeftSibling)
            LeftSibling.NodeOut();
        if (RightSibling)
            RightSibling.NodeOut();
    }

    /*
        Returns a collection of elements
        matching the given name.  Searching
        will begin at the given root.
    */
    clearscope void FindElements(string Name, in ZMLNode Root, in out array<ZMLNode> Elements)
    {
        if (Root.Name == Name)
            Elements.Push(Root);

        if (Root.Children)
            Root.Children.FindElements(Name, Root.Children, Elements);
        if (Root.LeftSibling)
            Root.LeftSibling.FindElements(Name, Root.LeftSibling, Elements);
        if (Root.RightSibling)
            Root.RightSibling.FindElements(Name, Root.RightSibling, Elements);
    }

    clearscope ZMLNode FindElement(string Name, in ZMLNode Root)
    {
        if (Root.Name == Name)
            return Root;

        ZMLNode n = null;
        if (Root.LeftSibling)
            n = Root.LeftSibling.FindElement(Name, Root.LeftSibling);
        if (!n && Root.RightSibling)
            n = Root.RightSibling.FindElement(Name, Root.RightSibling);

        return n;
    }

    clearscope ZMLAttribute FindAttribute(string Name)
    {
        for (int i = 0; i < Attributes.Size(); i++)
        {
            if (Attributes[i].Name == Name)
                return Attributes[i];
        }
        return null;
    }

    /* - END OF METHODS - */
}


/*
    You are the little tumor on my otherwise nice XML parser
*/
class ZMLAttribute
{
    string Name, Value;

    ZMLAttribute Init(string Name, string Value)
    {
        self.Name = Name;
        self.Value = Value;
        return self;
    }

    /* - END OF METHODS - */
}