import 'dart:math' as math;
import 'package:image/image.dart' as img;

class Fingerprint {
  final String ahash;
  final String dhash;
  final List<double> color;
  const Fingerprint(this.ahash, this.dhash, this.color);

  static Fingerprint fromBytes(List<int> bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('تعذر قراءة الصورة');
    final side = math.min(decoded.width, decoded.height);
    final x0 = (decoded.width - side) ~/ 2;
    final y0 = (decoded.height - side) ~/ 2;
    final sample = img.copyResize(
      img.copyCrop(decoded, x: x0, y: y0, width: side, height: side),
      width: 17, height: 16,
    );
    final gray = <double>[];
    var r = 0.0, g = 0.0, b = 0.0;
    for (var y=0; y<16; y++) {
      for (var x=0; x<16; x++) {
        final p = sample.getPixel(x,y);
        final pr=p.r.toDouble(), pg=p.g.toDouble(), pb=p.b.toDouble();
        r += pr; g += pg; b += pb;
        gray.add(.299*pr + .587*pg + .114*pb);
      }
    }
    final mean = gray.reduce((a,c)=>a+c)/gray.length;
    final aBits = gray.map((v)=>v>=mean).toList();
    final dBits = <bool>[];
    for (var y=0; y<16; y++) {
      for (var x=0; x<16; x++) {
        final p1=sample.getPixel(x,y), p2=sample.getPixel(x+1,y);
        final g1=.299*p1.r+.587*p1.g+.114*p1.b;
        final g2=.299*p2.r+.587*p2.g+.114*p2.b;
        dBits.add(g1>g2);
      }
    }
    return Fingerprint(_hex(aBits), _hex(dBits), [r/256,g/256,b/256]);
  }

  static String _hex(List<bool> bits) {
    final out=StringBuffer();
    for (var i=0; i<bits.length; i+=4) {
      var n=0;
      for (var j=0; j<4; j++) { if(bits[i+j]) n |= 1 << (3-j); }
      out.write(n.toRadixString(16));
    }
    return out.toString();
  }

  static int _distance(String a, String b) {
    var total=0;
    for(var i=0;i<a.length && i<b.length;i++) {
      total += (int.parse(a[i],radix:16)^int.parse(b[i],radix:16))
          .toRadixString(2).replaceAll('0','').length;
    }
    return total;
  }

  double score(Fingerprint other) {
    final ad=_distance(ahash,other.ahash)/256;
    final dd=_distance(dhash,other.dhash)/256;
    final dr=color[0]-other.color[0], dg=color[1]-other.color[1], db=color[2]-other.color[2];
    final cd=math.sqrt(dr*dr+dg*dg+db*db)/441.673;
    return .42*ad+.42*dd+.16*cd;
  }
}
