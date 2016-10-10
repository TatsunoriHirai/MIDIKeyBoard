//
// Tatsunori Hirai, 2016
//

// themidibusライブラリのインポート
import themidibus.*; //Import the MIDI library（http://www.smallbutdigital.com/themidibus.php）


// 変数の宣言
int w, h; // 画面の横幅，高さを入れる変数
int nOctave = 2; // オクターブの数
int nWPC = 7; // 1オクターブあたりの白鍵の数(number of black keys per octave)
int nKey = nWPC*nOctave+1; // 全体の白鍵の個数(１つ上のC込み)
int nBPC = 5; // 1オクターブあたりの黒鍵の数(number of black keys per octave)
int k_width; // 鍵盤の横幅
int b_width, b_height; // 黒鍵の横幅，高さ
int[] keypos_w = new int[nKey]; // 白鍵のx軸の座標
int[] keypos_b = new int[nBPC*nOctave+1]; // 黒鍵のx軸の座標
int currentKey_w = -1; // 現在押されている白鍵（押されていない場合は-1）
int currentKey_b = -1; // 現在押されている黒鍵（押されていない場合は-1）
int baseOct = 0; // キーボード入力用のベースとなるオクターブ（↑↓カーソルで切り替え）

// MIDI用変数
MidiBus myBus; // The MidiBus object
int channel = 0; // 音源のchannel
int basepitch = 60; // 基準ピッチ：C4（※C#4なら61，D4なら62）
int velocity = 127; // 鍵盤を押す強さ（0-127）
int pitch; // 現在のピッチ

void settings() { // GUIの画面の設定
  w = displayWidth/2; // 画面の横幅（の半分）の取得
  h = displayHeight/2; // 画面の高さ（の半分）の取得
  if (nOctave>1) { // 2オクターブ以上表示する場合，画面を大きくする
    w = int(w*pow(1.2, nOctave-1));
    h = int(h*pow(1.2, nOctave-1));
  }
  size( w, h ); // 画面サイズの設定
}

void setup() { // 初期設定（プログラム実行時に一度だけ呼び出される）

  // 鍵盤のサイズの設定
  k_width = w/nKey;
  b_height = 3*h/5;
  b_width = 2*k_width/3;

  // PCのMIDI情報の取得．デバイスの設定（PC毎に違う設定になる） ---------
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, 0, 1); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
  // myBus = new MidiBus(this, 0, 1); // 音が鳴らない場合は「0,1」の部分を，「0,0」や「-1，-1」等の「ｰ1,0,1,2」の組み合わせを試す
  // --------------------------------------------------------------------

  // 各鍵盤のX座標の設定
  for (int i=0; i<nKey; i++) {
    keypos_w[i] = i*k_width; // 白鍵のx軸の座標
  }
  for (int i=0; i<nOctave; i++) {
    keypos_b[i*nBPC] = i*nWPC*k_width+k_width-b_width/2;
    keypos_b[i*nBPC+1] = i*nWPC*k_width+2*k_width-b_width/2;
    keypos_b[i*nBPC+2] = i*nWPC*k_width+4*k_width-b_width/2;
    keypos_b[i*nBPC+3] = i*nWPC*k_width+nBPC*k_width-b_width/2;
    keypos_b[i*nBPC+4] = i*nWPC*k_width+6*k_width-b_width/2;
    keypos_b[i*nBPC+nBPC] = i*nWPC*k_width+8*k_width-b_width/2;
  }
}

void draw() { // 描画部分

  // 鍵盤の描画（白鍵）
  color(255); // 色を白にする
  fill(255);
  for (int i=0; i<nKey; i++) {
    rect(keypos_w[i], 0, k_width, h);
  }
  // 押されている鍵盤を赤く塗りつぶす
  if (currentKey_w!=-1) {
    color(255, 0, 0); // 色を赤にする
    fill(255, 0, 0); // 赤で塗りつぶす
    rect(keypos_w[currentKey_w], 0, k_width, h);
  }

  // 鍵盤の描画（黒鍵）
  color(0); // 色を黒にする
  fill(0); // 黒で塗りつぶす
  for (int i=0; i<nOctave; i++) {
    rect(keypos_b[i*nBPC], 0, b_width, b_height); // C#の黒鍵
    rect(keypos_b[i*nBPC+1], 0, b_width, b_height); // D#の黒鍵
    rect(keypos_b[i*nBPC+2], 0, b_width, b_height); // F#の黒鍵
    rect(keypos_b[i*nBPC+3], 0, b_width, b_height); // G#の黒鍵
    rect(keypos_b[i*nBPC+4], 0, b_width, b_height); // A#の黒鍵
  }
  rect(keypos_b[nOctave*nBPC], 0, b_width, b_height); // C#↑の黒鍵
  // 押されている鍵盤を赤く塗りつぶす
  if (currentKey_b!=-1) {
    color(255, 0, 0); // 色を赤にする
    fill(255, 0, 0); // 赤で塗りつぶす
    rect(keypos_b[currentKey_b], 0, b_width, b_height);
  }

  //myBus.sendControllerChange(channel, number, value); // Send a controllerChange
}

void mousePressed() { // マウスが押されたときの動作
  println("Note on:");

  boolean bPressed = false;
  for (int i=0; i<keypos_b.length; i++) {
    if ((mouseX>keypos_b[i])&&(mouseX<keypos_b[i]+b_width)&&(mouseY<b_height)) {
      int octave_plus = floor(i/nBPC); // 基準より何オクターブ上か？
      if (i%nBPC==0) {
        println("black key: C#"+octave_plus);
        pitch = basepitch + 1 + 12 * octave_plus;
        currentKey_b = 0 + octave_plus*nBPC;
      } else if (i%nBPC==1) {
        println("black key: D#"+octave_plus);
        pitch = basepitch + 3 + 12 * octave_plus;
        currentKey_b = 1 + octave_plus*nBPC;
      } else if (i%nBPC==2) {
        println("black key: F#"+octave_plus);
        pitch = basepitch + 6 + 12 * octave_plus;
        currentKey_b = 2 + octave_plus*nBPC;
      } else if (i%nBPC==3) {
        println("black key: G#"+octave_plus);
        pitch = basepitch + 8 + 12 * octave_plus;
        currentKey_b = 3 + octave_plus*nBPC;
      } else if (i%nBPC==4) {
        println("black key: A#"+octave_plus);
        pitch = basepitch + 10 + 12 * octave_plus;
        currentKey_b = 4 + octave_plus*nBPC;
      }
      bPressed = true;
      break;
    }
  }
  if (!bPressed) {
    for (int i=0; i<nKey; i++) {
      if ((mouseX>keypos_w[i])&&(mouseX<keypos_w[i]+k_width)) {
        int octave_plus = floor(i/nWPC); // 基準より何オクターブ上か？
        if (i%nWPC==0) { // low C has been pressed
          println("white key: C"+octave_plus);
          pitch = basepitch + 12 * octave_plus;
          currentKey_w = 0 + octave_plus*nWPC;
        } else if (i%nWPC==1) { // D has been pressed
          println("white key: D"+octave_plus);
          pitch = basepitch + 2 + 12 * octave_plus;
          currentKey_w = 1 + octave_plus*nWPC;
        } else if (i%nWPC==2) { // E has been pressed
          println("white key: E"+octave_plus);
          pitch = basepitch + 4 + 12 * octave_plus;
          currentKey_w = 2 + octave_plus*nWPC;
        } else if (i%nWPC==3) { // E has been pressed
          println("white key: F"+octave_plus);
          pitch = basepitch + 5 + 12 * octave_plus;
          currentKey_w = 3 + octave_plus*nWPC;
        } else if (i%nWPC==4) { // F has been pressed
          println("white key: G"+octave_plus);
          pitch = basepitch + 7 + 12 * octave_plus;
          currentKey_w = 4 + octave_plus*nWPC;
        } else if (i%nWPC==nBPC) { // G has been pressed
          println("white key: A"+octave_plus);
          pitch = basepitch + 9 + 12 * octave_plus;
          currentKey_w = 5 + octave_plus*nWPC;
        } else if (i%nWPC==6) { // A has been pressed
          println("white key: B"+octave_plus);
          pitch = basepitch + 11 + 12 * octave_plus;
          currentKey_w = 6 + octave_plus*nWPC;
        }
        break;
      }
    }
  }
  myBus.sendNoteOn(channel, pitch, velocity); // MIDIの音を鳴らす（Note on）
}

void mouseReleased() { // マウスが離されたときの動作
  println("Note off:");
  currentKey_w = -1;
  currentKey_b = -1;
  myBus.sendNoteOff(channel, pitch, velocity); // MIDIの音を止める（Note off）
}

void keyPressed() {
  boolean effectiveKey = false; // 鍵盤操作に有効なキーが押されていない状態
  if ((key=='a')||(key=='A')) {// low C has been pressed
    println("white key: C");
    pitch = basepitch + 12 * baseOct;
    currentKey_w = 0 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='w')||(key=='W')) { // C# has been pressed
    println("white key: C#");
    pitch = basepitch + 1 + 12 * baseOct;
    currentKey_b = 0 + baseOct*nBPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='s')||(key=='S')) { // D has been pressed
    println("white key: D");
    pitch = basepitch + 2 + 12 * baseOct;
    currentKey_w = 1 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='e')||(key=='E')) { // D# has been pressed
    println("white key: D#");
    pitch = basepitch + 3 + 12 * baseOct;
    currentKey_b = 1 + baseOct*nBPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='d')||(key=='D')) { // E has been pressed
    println("white key: E");
    pitch = basepitch + 4 + 12 * baseOct;
    currentKey_w = 2 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='f')||(key=='F')) { // F has been pressed
    println("white key: F");
    pitch = basepitch + 5 + 12 * baseOct;
    currentKey_w = 3 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='t')||(key=='T')) { // F# has been pressed
    println("white key: F#");
    pitch = basepitch + 6 + 12 * baseOct;
    currentKey_b = 2 + baseOct*nBPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='g')||(key=='G')) { // G has been pressed
    println("white key: G");
    pitch = basepitch + 7 + 12 * baseOct;
    currentKey_w = 4 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='y')||(key=='Y')) { // G# has been pressed
    println("white key: G#");
    pitch = basepitch + 8 + 12 * baseOct;
    currentKey_b = 3 + baseOct*nBPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='h')||(key=='H')) { // A has been pressed
    println("white key: A");
    pitch = basepitch + 9 + 12 * baseOct;
    currentKey_w = 5 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='u')||(key=='U')) { // A# has been pressed
    println("white key: A#");
    pitch = basepitch + 10 + 12 * baseOct;
    currentKey_b = 4 + baseOct*nBPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='j')||(key=='J')) { // B has been pressed
    println("white key: B");
    pitch = basepitch + 11 + 12 * baseOct;
    currentKey_w = 6 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((key=='k')||(key=='K')) { // high C has been pressed
    println("white key: C++");
    pitch = basepitch + 12 + 12 * baseOct;
    currentKey_w = 7 + baseOct*nWPC;
    effectiveKey = true; // 鍵盤操作に有効なキーが押された状態にする
  } else if ((keyCode==UP)||(keyCode==RIGHT)||(keyCode==SHIFT)) { // cursor UP/RIGHT/SHIFT has been pressed
    if (baseOct<nOctave-1) { // キーボード入力用のオクターブを上げる
      println("octave++");
      baseOct = baseOct + 1;
    }
  } else if ((keyCode==DOWN)||(keyCode==LEFT)) { // cursor DOWN/LEFT has been pressed
    if (baseOct>0) { // キーボード入力用のオクターブを下げる
      println("octave--");
      baseOct = baseOct - 1;
    }
  }
  if (effectiveKey) { // 音を鳴らすのに有効なキーが押されていた場合
    myBus.sendNoteOn(channel, pitch, velocity); // MIDIの音を鳴らす（Note on）
  }
}

void keyReleased() {
  currentKey_w = -1;
  currentKey_b = -1;
  myBus.sendNoteOff(channel, pitch, velocity); // MIDIの音を止める（Note off）
}