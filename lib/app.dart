import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'services/store.dart';
import 'services/fingerprint.dart';

const purple = Color(0xFF69008A);
const gold = Color(0xFFFFC400);

class BikamApp extends StatefulWidget {
  final ProductStore store;
  final SharedPreferences prefs;
  const BikamApp({super.key, required this.store, required this.prefs});
  @override State<BikamApp> createState()=>_BikamAppState();
}
class _BikamAppState extends State<BikamApp> {
  late String lang=widget.prefs.getString('bikam.lang')??'ar';
  late bool dark=widget.prefs.getBool('bikam.dark')??false;
  late String font=widget.prefs.getString('bikam.font')??'md';
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'بكم؟',
      themeMode:dark?ThemeMode.dark:ThemeMode.light,
      theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:purple),scaffoldBackgroundColor:const Color(0xFFF8F5FA),useMaterial3:true,fontFamily:'Tajawal'),
      darkTheme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:purple,brightness:Brightness.dark),useMaterial3:true,fontFamily:'Tajawal'),
      builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(font=='sm'?.9:font=='lg'?1.12:1)),child:Directionality(textDirection:lang=='ar'?TextDirection.rtl:TextDirection.ltr,child:child!)),
      home: MainScreen(store:widget.store,lang:lang,dark:dark,font:font,
        onLang:(v){setState(()=>lang=v);widget.prefs.setString('bikam.lang',v);},
        onDark:(v){setState(()=>dark=v);widget.prefs.setBool('bikam.dark',v);},
        onFont:(v){setState(()=>font=v);widget.prefs.setString('bikam.font',v);}),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ProductStore store; final String lang; final bool dark; final String font;
  final ValueChanged<String> onLang; final ValueChanged<bool> onDark; final ValueChanged<String> onFont;
  const MainScreen({super.key,required this.store,required this.lang,required this.dark,required this.font,required this.onLang,required this.onDark,required this.onFont});
  @override State<MainScreen> createState()=>_MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int tab=0; String? selectedMarket;
  bool get ar=>widget.lang=='ar';
  String tr(String a,String e)=>ar?a:e;
  Future<void> addProduct(String market) async {
    final picker=ImagePicker();
    final picked=await showModalBottomSheet<XFile?>(context:context,builder:(ctx)=>SafeArea(child:Wrap(children:[
      ListTile(leading:const Icon(Icons.camera_alt),title:Text(tr('التقاط صورة بالكاميرا','Take a photo')),onTap:()=>Navigator.pop(ctx, XFile('CAMERA'))),
      ListTile(leading:const Icon(Icons.photo_library),title:Text(tr('اختيار من المعرض','Choose from gallery')),onTap:()=>Navigator.pop(ctx,XFile('GALLERY'))),
    ])));
    if(picked==null)return;
    XFile? file;
    if(picked.path=='CAMERA') file=await picker.pickImage(source:ImageSource.camera,imageQuality:78,maxWidth:1000);
    else file=await picker.pickImage(source:ImageSource.gallery,imageQuality:78,maxWidth:1000);
    if(file==null)return;
    try {
      final bytes=await file.readAsBytes();
      final fp=Fingerprint.fromBytes(bytes);
      final nameCtrl=TextEditingController(), priceCtrl=TextEditingController(), wholesaleCtrl=TextEditingController();
      String size='none';
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
        title:Text(tr('بيانات المنتج','Product details')),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.memory(bytes,height:130,width:130,fit:BoxFit.cover)),
          const SizedBox(height:12),
          TextField(controller:nameCtrl,decoration:InputDecoration(labelText:tr('اسم المنتج','Product name'))),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(value:size,decoration:InputDecoration(labelText:tr('الحجم','Size')),items:[
            DropdownMenuItem(value:'large',child:Text(tr('كبير','Large'))),
            DropdownMenuItem(value:'medium',child:Text(tr('متوسط','Medium'))),
            DropdownMenuItem(value:'small',child:Text(tr('صغير','Small'))),
            DropdownMenuItem(value:'none',child:Text(tr('بدون','None'))),
          ],onChanged:(v)=>setD(()=>size=v??'none')),
          TextField(controller:priceCtrl,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:tr('السعر (د.ل)','Price (LYD)'))),
          TextField(controller:wholesaleCtrl,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:tr('سعر الجملة (اختياري)','Wholesale price (optional)'))),
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(tr('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(tr('حفظ','Save')))],
      )));
      if(ok!=true)return;
      final price=double.tryParse(priceCtrl.text.replaceAll(',','.'));
      if(nameCtrl.text.trim().isEmpty||price==null||price<0){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('أدخل الاسم والسعر بشكل صحيح','Enter a valid name and price'))));return;}
      final wholesale=double.tryParse(wholesaleCtrl.text.replaceAll(',','.'));
      await widget.store.add(ProductItem(id:DateTime.now().microsecondsSinceEpoch.toString(),market:market,name:nameCtrl.text.trim(),size:size,price:price,wholesalePrice:wholesale,image:base64Encode(bytes),ahash:fp.ahash,dhash:fp.dhash,color:fp.color,createdAt:DateTime.now()));
      if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تمت إضافة المنتج بنجاح','Product added successfully'))));}
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${tr('تعذرت معالجة الصورة','Could not process image')}: $e')));
    }
  }

  Future<void> scan() async {
    final picker=ImagePicker();
    final source=await showModalBottomSheet<ImageSource>(context:context,builder:(ctx)=>SafeArea(child:Wrap(children:[
      ListTile(leading:const Icon(Icons.camera_alt),title:Text(tr('تصوير منتج','Take a photo')),onTap:()=>Navigator.pop(ctx,ImageSource.camera)),
      ListTile(leading:const Icon(Icons.photo_library),title:Text(tr('اختيار صورة','Choose an image')),onTap:()=>Navigator.pop(ctx,ImageSource.gallery)),
    ])));
    if(source==null)return;
    final file=await picker.pickImage(source:source,imageQuality:78,maxWidth:1000);
    if(file==null)return;
    try{
      final bytes=await file.readAsBytes(); final fp=Fingerprint.fromBytes(bytes);
      ProductItem? best; var score=999.0;
      for(final p in widget.store.products){
        final s=fp.score(Fingerprint(p.ahash,p.dhash,p.color));
        if(s<score){score=s;best=p;}
      }
      if(!mounted)return;
      showDialog(context:context,builder:(ctx)=>AlertDialog(
        title:Text(best!=null&&score<=.31?tr('تم العثور على المنتج','Product found'):tr('لم يتم العثور على المنتج','Product not found')),
        content:best!=null&&score<=.31?Column(mainAxisSize:MainAxisSize.min,children:[
          ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.memory(base64Decode(best.image),height:120,width:120,fit:BoxFit.cover)),
          const SizedBox(height:10),Text(best.name,style:Theme.of(context).textTheme.titleLarge),
          Text('${best.price.toStringAsFixed(2)} ${tr('د.ل','LYD')}'),
          if(best.wholesalePrice!=null)Text('${tr('الجملة','Wholesale')}: ${best.wholesalePrice!.toStringAsFixed(2)}'),
          Text('${tr('السوق','Market')}: ${marketName(best.market)}'),
        ]):Text(tr('هذا المنتج غير مضاف. أضفه أولاً من السوق المناسب.','This product is not in your list. Add it from its market first.')),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('إغلاق','Close')))],
      ));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}
  }

  String marketName(String id){final m=markets.firstWhere((m)=>m.id==id,orElse:()=>markets.first);return ar?m.ar:m.en;}
  @override Widget build(BuildContext context){
    final title=tab==0?tr('بكم؟','Bikam?'):tab==1?tr('الكاميرا','Camera'):tr('الإعدادات','Settings');
    return Scaffold(
      appBar:AppBar(title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900,color:purple)),centerTitle:true,backgroundColor:Theme.of(context).scaffoldBackgroundColor),
      body:tab==0?home():tab==1?cameraPage():settingsPage(),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:[
        NavigationDestination(icon:const Icon(Icons.home_outlined),selectedIcon:const Icon(Icons.home),label:tr('الرئيسية','Home')),
        NavigationDestination(icon:const Icon(Icons.camera_alt_outlined),selectedIcon:const Icon(Icons.camera_alt),label:tr('كاميرا','Camera')),
        NavigationDestination(icon:const Icon(Icons.settings_outlined),selectedIcon:const Icon(Icons.settings),label:tr('الإعدادات','Settings')),
      ]),
    );
  }

  Widget home(){
    if(selectedMarket!=null)return marketPage(selectedMarket!);
    return RefreshIndicator(onRefresh:()async=>setState((){}),child:ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[purple,Color(0xFF9200B7)]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(tr('صوّر أي منتج… واعرف سعره فوراً','Snap a product… know its price instantly'),style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:14),FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:gold,foregroundColor:purple),onPressed:scan,icon:const Icon(Icons.center_focus_strong),label:Text(tr('التعرف على منتج','Identify a product'))),
      ])),
      const SizedBox(height:22),
      Row(children:[Text(tr('الأسواق','Markets'),style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),const Spacer(),Text('${widget.store.products.length} ${tr('منتج','products')}')]),
      const SizedBox(height:12),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:markets.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.45),itemBuilder:(ctx,i){
        final m=markets[i];final count=widget.store.counts[m.id]??0;
        return Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>setState(()=>selectedMarket=m.id),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          CircleAvatar(backgroundColor:purple.withOpacity(.1),foregroundColor:purple,child:Icon(m.icon)),
          Text(ar?m.ar:m.en,style:const TextStyle(fontWeight:FontWeight.bold)),
          Text('$count ${tr('منتج','products')}',style:TextStyle(color:Theme.of(context).colorScheme.secondary)),
        ]))));
      }),
    ]));
  }

  Widget marketPage(String id){
    final m=markets.firstWhere((m)=>m.id==id);final items=widget.store.inMarket(id);
    return Column(children:[
      ListTile(leading:IconButton(onPressed:()=>setState(()=>selectedMarket=null),icon:const Icon(Icons.arrow_back)),title:Text(ar?m.ar:m.en,style:const TextStyle(fontWeight:FontWeight.bold)),trailing:FilledButton.icon(onPressed:()=>addProduct(id),icon:const Icon(Icons.add),label:Text(tr('إضافة','Add')))),
      Expanded(child:items.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(m.icon,size:56,color:purple.withOpacity(.5)),const SizedBox(height:12),Text(tr('لا توجد منتجات بعد','No products yet'),style:const TextStyle(fontWeight:FontWeight.bold)),Text(tr('أضف أول منتج لهذا السوق','Add the first product to this market'))])):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(ctx,i){
        final p=items[i];
        return Card(child:ListTile(leading:ClipRRect(borderRadius:BorderRadius.circular(9),child:Image.memory(base64Decode(p.image),width:58,height:58,fit:BoxFit.cover)),title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${sizeName(p.size)}  •  ${p.price.toStringAsFixed(2)} ${tr('د.ل','LYD')}${p.wholesalePrice==null?'':'  •  ${tr('جملة','Wholesale')}: ${p.wholesalePrice!.toStringAsFixed(2)}'}'),trailing:IconButton(icon:const Icon(Icons.delete_outline,color:Colors.red),onPressed:()async{await widget.store.remove(p.id);setState((){});}),));
      })),
    ]);
  }
  String sizeName(String s)=>({'large':tr('كبير','Large'),'medium':tr('متوسط','Medium'),'small':tr('صغير','Small'),'none':tr('بدون','None')}[s]??s);

  Widget cameraPage()=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Container(width:150,height:150,decoration:BoxDecoration(color:purple.withOpacity(.09),shape:BoxShape.circle),child:const Icon(Icons.camera_alt_outlined,size:76,color:purple)),
    const SizedBox(height:20),Text(tr('صوّر المنتج','Photograph a product'),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),Text(tr('التقط صورة أو اخترها من الملفات للتعرف على المنتج ومقارنة بصمته بالمنتجات المحفوظة.','Take or choose a photo to match it with saved products.'),textAlign:TextAlign.center),
    const SizedBox(height:22),FilledButton.icon(onPressed:scan,icon:const Icon(Icons.camera),label:Text(tr('بدء التعرف','Start identification'))),
  ])));
  Widget settingsPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(tr('الإعدادات','Settings'),style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
    const SizedBox(height:10),
    Card(child:ListTile(leading:const Icon(Icons.language),title:Text(tr('اللغة','Language')),trailing:DropdownButton<String>(value:widget.lang,items:[DropdownMenuItem(value:'ar',child:const Text('العربية')),DropdownMenuItem(value:'en',child:const Text('English'))],onChanged:(v){if(v!=null)widget.onLang(v);}))),
    Card(child:SwitchListTile(secondary:const Icon(Icons.dark_mode_outlined),title:Text(tr('الوضع الداكن','Dark mode')),value:widget.dark,onChanged:widget.onDark)),
    Card(child:ListTile(leading:const Icon(Icons.text_fields),title:Text(tr('حجم الخط','Font size')),trailing:DropdownButton<String>(value:widget.font,items:[DropdownMenuItem(value:'sm',child:Text(tr('صغير','Small'))),DropdownMenuItem(value:'md',child:Text(tr('متوسط','Medium'))),DropdownMenuItem(value:'lg',child:Text(tr('كبير','Large')))],onChanged:(v){if(v!=null)widget.onFont(v);}))),
    const SizedBox(height:20),Center(child:Column(children:[Image.asset('assets/app_icon.png',width:76,height:76),const SizedBox(height:8),const Text('بكم؟ • الإصدار 1.0',style:TextStyle(fontWeight:FontWeight.bold)),const Text('المبرمج احمد امليمدي')]))
  ]);
}
