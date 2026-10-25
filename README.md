#  Japanese to English restaurant menu translation

Just an experiment to develop my own Japanese restaurant menu translation. 

Currently using OCR with **VNRecognizeTextRequest** and translation using **TranslationSession**.

Next step is to try AI, the **Vision** framework or something like that.

To get the katakana data from sql

sqlite3 loanwords.sqlite < merged.sql

sqlite3 -json loanwords.sqlite 'SELECT japanese, english FROM merged' > loanwords.json


https://raw.githubusercontent.com/jamesohortle/loanwords_gairaigo/master/loanwords_gairaigo/db/merged.sql

sqlite3 AltData.sqlite < AltData.sql

sqlite3 -json AltData.sqlite 'SELECT japanese, english FROM merged' > AltData.json
 
see also 

https://github.com/KEINOS/google-ime-user-dictionary-ja-en/tree/master

https://github.com/jamesohortle/loanwords_gairaigo

https://github.com/scriptin/jmdict-simplified

and https://github.com/scriptin/jmdict-simplified/releases/tag/3.6.2+20261019180022

using bash to combine .txt files into one full.txt

for f in *.txt; do
  [[ $f == full.txt ]] || cat "$f"
done > full.txt

Note:
loadAllwords() "katakana-eng.json" is now the merging of "google-ime-user-dictionary-ja-en" and "jmdict-simplified" 
adding the small data from somewhere and removing duplicates and the ";" in the English text.


Experimenting with [Swift Image Understanding](https://github.com/arraypress/swift-image-understanding) , "A Swift library for asking Apple's on-device foundation model about images — describe, answer questions, and extract structured JSON."




