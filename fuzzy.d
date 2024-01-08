import std.stdio:writeln, writef, File, getchar;
import std.string:leftJustify, splitLines;
import std.file:dirEntries, SpanMode, read, DirEntry, exists;
import std.array: split;
import core.stdc.stdlib:exit;
import std.algorithm: min, max;
import std.parallelism:parallel;
import std.concurrency:spawn;
import core.sys.posix.termios;

const int MAXCHAR = 50;
long score(const string src, const string dest){
  long[MAXCHAR*MAXCHAR] mem;
  bool[MAXCHAR*MAXCHAR] vis;

  long editDist(long idx1, long idx2){
    if(idx1 < 0) return idx2+1;
    if(idx2 < 0) return idx1+1;
    if(vis[idx1*MAXCHAR+idx2]) return mem[idx1*MAXCHAR+idx2];
    // weighted edit distance
    vis[idx1*MAXCHAR+idx2] = true;
    return mem[idx1*MAXCHAR+idx2] = min(
      editDist(idx1-1,idx2-1)+ 2*(src[idx1] != dest[idx2]) - (src[idx1] == dest[idx2]),
      editDist(idx1-1,idx2) + 1,
      editDist(idx1,idx2-1) + 1,
      );
  }
  return editDist(src.length-1,min(src.length,dest.length)-1); 
}

const int MAXFILES = 65535;

enum Type{
  ALL, SKIPPABLE
}

struct FileInfo{
  DirEntry dirInfo;
  string name;
  string absoluteLoc;
  long score = 0;
}

bool[string] nolook;
struct Spider{
  string currDir;
  FileInfo[] list;
  size_t pos = 0;
  Type type;

  void add(){
    switch(type){
      case Type.ALL:
        foreach(file ; dirEntries(currDir,SpanMode.shallow,false)){
          auto temp = cast(string)(file.name.split('/')[$-1]);
          FileInfo Struct = {dirInfo : file, name : temp, absoluteLoc:file.name};
          list ~= Struct;
        }
        break;
      case Type.SKIPPABLE:
        foreach(file ; dirEntries(currDir,SpanMode.shallow,false)){
          auto temp = cast(string)(file.name.split('/')[$-1]);
          if(!(temp in nolook))
          {
            FileInfo Struct = {dirInfo : file, name: temp, absoluteLoc:file.name};
            list ~= Struct;
          }
        }
        break;
      default:
        writeln("BROKEN");
        exit(1);
    }
  }
        

  this(string DIR){
    currDir = DIR;
    if(nolook.length)
      type = Type.SKIPPABLE;
    else
      type = Type.ALL;
    add();

  }

  bool empty(){
    return pos >= list.length;
  }
  FileInfo front(){
    return list[pos];
  }
  void popFront(){
    if(list[pos].dirInfo.isDir){
      currDir = list[pos].dirInfo.name;
      add();
    }
    pos++;
  }
}


// TUI FUNCTION
const size_t OPTIONS = 5;

void clean(){
  for(size_t t = 0; t < OPTIONS;++t) writeln();
}

size_t getCols(){
  size_t cols;
  File f;
  f.popen("tput cols","r");
  f.readf("%u",&cols);
  f.close();
  return cols;
}

void printLines(shared string[] options, const string header, size_t highlight){
  writef("\x1b[%uF\x1b[0J",OPTIONS+1);
  writeln(header);
  assert(options.length == OPTIONS);
  size_t maxLen = 0;
  foreach(x;options)
    maxLen = max(maxLen, x.length);
  maxLen = min(maxLen,getCols()-3);
  foreach(i,val;options){
    auto temp = min(val.length,maxLen);
    if(i != highlight)
      writeln(val[$-temp..$]);
    else
      writeln("\x1b[30;107m",leftJustify(val[$-temp..$],maxLen+2,' '),"\x1b[0m");
  }
}



// TUI ENDS

// BST BEGINS
struct Node{
  long val;
  int size = 0;
  string[] topScores;
  string loc = "";
  Node* left, right;
  this(long val, string loc ){
    this.val = val;
    this.loc = loc;
  }
  void add(long nval, string nloc){
    size++;
    if(nval > val){
      //right
      if(right){
        (*right).add(nval,nloc);
      }
      else{
        right = new Node(nval,nloc);
      }

    }
    else{
      //left
      if(left){
        (*left).add(nval,nloc);
      }
      else{
        left = new Node(nval,nloc);
      }
    }
  }

  void updateTopScores(){
    if(left){
      (*left).updateTopScores();
      foreach(i;(*left).topScores){
        topScores ~= i;
      }
    }
    topScores ~= loc;
    if(right){
      (*right).updateTopScores();
      foreach(i;(*right).topScores){
        topScores ~= i;
      }
    }
  }

  Node* pruneLast(){
    size--;
    if(right){
      right = (*right).pruneLast();
      return &this;
    }
    else{
      if(left){
        return left;
      }
      else return null;
    }
  }


}

// BST ENDS



void readAllowedFiles(ref bool[string] nolook) {
  string[] lines;
  if(exists("~/.config/fz/.fzignore"))
    lines = (cast(string)read("~/.config/fz/.fzignore")).splitLines();
  else if(exists("~/.fzignore"))
    lines = (cast(string)read("~/.fzignore")).splitLines();
  else return;
  foreach(line;lines){
    if(line.length == 0) continue;
    nolook[line] = true;
  }

}

shared string[OPTIONS] results;

shared string toFind;
shared bool change = true;
shared int highlight = 0;

shared FileInfo[] sharedAllFiles;
void find(){
  while(true){
    while(!change){}
    foreach(ref x;parallel(sharedAllFiles))
      x.score = score(toFind, x.name);
    Node root = Node(-1, "");
    foreach(x;sharedAllFiles){
      root.add(x.score, x.absoluteLoc);
      if(root.size > OPTIONS)
        root.pruneLast();
    }
    root.updateTopScores();
    foreach(i,r;root.topScores[1..$]){
      results[i] = r;
    }
    renderChange = true;
    change=false;
  }
  return;
}

shared renderChange = true;
void render(){
  while(true){
    while(!renderChange){}
    printLines(results,toFind,highlight);
    renderChange = false;
  }
}

  

int main(){
  clean();
  readAllowedFiles(nolook);
  auto sp = Spider("/home");
  FileInfo[] allFiles;

  foreach(x;(sp))
    allFiles ~= x;
  sharedAllFiles = new FileInfo[allFiles.length];
  foreach(x;0..allFiles.length)
    sharedAllFiles[x] = cast(shared(FileInfo))allFiles[x];

  termios term, oldTerm;

  tcgetattr(0, &term);
  oldTerm = term;
  term.c_lflag &= ~ICANON;
  term.c_cc[VMIN] = 1;
  term.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &term);

  char[MAXCHAR] keyboardInput;
  int strLen = 0;
  spawn(&find);
  spawn(&render);
  toFind = "";
  while(true){
    int c = getchar();
    renderChange=true;
    if(c == 127){
      if(strLen > 0){
        strLen--;
        keyboardInput[strLen] = 0;
        toFind = cast(string)keyboardInput;
        change=true;
      }
    }
    else if(c == 9){
      highlight=(highlight+1)%OPTIONS;
    }
    else if(c == 10){
      tcsetattr(0, TCSANOW, &oldTerm);
      File f = File("/tmp/chd","w");
      auto checkIsDIR = DirEntry(results[highlight]);
      if(checkIsDIR.isDir)
        f.writef("%s",results[highlight]);
      else
        foreach(i;results[highlight]
            .split('/')[1..$-1])
          f.writef("/%s",i);
      f.close();
      exit(0);
    }
    else{
      if(strLen < keyboardInput.length)
        keyboardInput[strLen] = cast(char)c;
      strLen++;
      toFind = cast(string)keyboardInput;
      change=true;
    }

  }


  return 0;

}
