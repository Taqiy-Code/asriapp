import 'package:flutter/material.dart';

import '../models/jenis_sampah.dart';
import '../services/jenis_sampah_service.dart';
import '../services/setor_sampah_service.dart';
import '../user/activity_riwayat.dart';

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});

  @override
  State<SetorSampahScreen> createState() =>
      _SetorSampahScreenState();
}

class _SetorSampahScreenState
    extends State<SetorSampahScreen> {

  JenisSampah? selectedJenis;

  List<JenisSampah> daftarJenis = [];

  bool isLoading = true;

  final catatanController =
  TextEditingController();


  @override
  void initState() {
    super.initState();

    loadJenis();
  }


  @override
  void dispose() {
    catatanController.dispose();

    super.dispose();
  }


  Future<void> loadJenis() async {

    daftarJenis =
    await JenisSampahService.getData();

    if(!mounted) return;

    setState(() {
      isLoading = false;
    });
  }


  String getIcon(String kode){

    switch(kode){

      case "plastik":
        return "assets/images/plastik.png";

      case "kertas":
        return "assets/images/kertas.png";

      case "logam":
        return "assets/images/metal.png";

      case "organik":
        return "assets/images/organik.png";

      default:
        return "assets/images/plastik.png";
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xffe5e5e5),

      body: SafeArea(
        child: ListView(
          padding:
          const EdgeInsets.only(
            bottom: 20,
          ),

          children: [

            /// HEADER
            Container(
              height: 140,

              decoration:
              const BoxDecoration(
                color: Color(
                  0xff2f5d2f,
                ),

                borderRadius:
                BorderRadius.only(
                  bottomLeft:
                  Radius.circular(40),

                  bottomRight:
                  Radius.circular(40),
                ),
              ),

              child: Row(
                children: [

                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),

                    onPressed: (){
                      Navigator.pop(
                        context,
                      );
                    },
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Setor Sampah",

                        style:
                        TextStyle(
                          color:
                          Colors.white,

                          fontSize:
                          20,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 40,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            /// JENIS SAMPAH
            Container(
              margin:
              const EdgeInsets
                  .symmetric(
                horizontal: 20,
              ),

              padding:
              const EdgeInsets
                  .all(15),

              decoration:
              BoxDecoration(
                color:
                Colors.grey[200],

                borderRadius:
                BorderRadius
                    .circular(
                  15,
                ),

                boxShadow:
                const [
                  BoxShadow(
                    color:
                    Colors.black26,

                    blurRadius: 5,
                  )
                ],
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  const Text(
                    "Jenis Sampah",

                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.bold,

                      color:
                      Color(
                        0xFF2E7D32,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  isLoading

                      ? const Center(
                    child:
                    CircularProgressIndicator(),
                  )

                      : Wrap(
                    spacing: 12,
                    runSpacing: 12,

                    children:
                    daftarJenis.map(
                            (item){

                          return _itemSampah(
                            item,
                          );

                        }).toList(),
                  )
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            /// CATATAN
            Container(
              margin:
              const EdgeInsets
                  .symmetric(
                horizontal: 20,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFECECEC,
                ),

                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black
                        .withOpacity(
                      0.15,
                    ),

                    blurRadius: 6,

                    offset:
                    const Offset(
                      0,
                      3,
                    ),
                  )
                ],
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),

                    decoration:
                    const BoxDecoration(
                      border:
                      Border(
                        bottom:
                        BorderSide(
                          color:
                          Colors.grey,
                        ),
                      ),
                    ),

                    child:
                    const Text(
                      "Catatan Tambahan",

                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.bold,

                        color:
                        Color(
                          0xFF2E7D32,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets
                        .all(15),

                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        const Icon(
                          Icons.note_alt,

                          color:
                          Color(
                            0xFF2E7D32,
                          ),

                          size: 35,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                          TextField(

                            controller:
                            catatanController,

                            minLines: 1,

                            maxLines:
                            null,

                            keyboardType:
                            TextInputType
                                .multiline,

                            decoration:
                            InputDecoration(

                              hintText:
                              "Tambahkan catatan...",

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                15,

                                vertical:
                                10,
                              ),

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            /// BUTTON
            Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 20,
              ),

              child: SizedBox(
                height: 50,

                child:
                ElevatedButton.icon(

                  style:
                  ElevatedButton
                      .styleFrom(

                    backgroundColor:
                    const Color(
                      0xFF2D5A27,
                    ),

                    foregroundColor:
                    Colors.white,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        30,
                      ),
                    ),
                  ),

                  onPressed:
                      () async {

                    if(selectedJenis
                        == null){

                      ScaffoldMessenger
                          .of(
                        context,
                      ).showSnackBar(

                        const SnackBar(
                          content:
                          Text(
                            "Pilih jenis sampah dulu",
                          ),
                        ),
                      );

                      return;
                    }


                    final berhasil =
                    await SetorSampahService
                        .store(

                      userId: 1,

                      jenisId:
                      selectedJenis!
                          .id,

                      catatan:
                      catatanController
                          .text,
                    );


                    if(!mounted)
                      return;


                    if(berhasil){

                      await showDialog(

                        context:
                        context,

                        barrierDismissible:
                        false,

                        builder:
                            (_) {

                          return AlertDialog(

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),

                            title:
                            const Text(
                              "Berhasil",
                            ),

                            content:
                            const Text(

                              "Pengajuan penjemputan berhasil dikirim.",

                            ),

                            actions: [

                              TextButton(

                                onPressed:
                                    () {

                                  Navigator.pop(
                                    context,
                                  );
                                },

                                child:
                                const Text(
                                  "OK",
                                ),
                              )
                            ],
                          );
                        },
                      );


                      if(!mounted)
                        return;


                      Navigator.pushReplacement(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_) =>
                          const RiwayatPage(),
                        ),
                      );

                    }else{

                      ScaffoldMessenger
                          .of(
                        context,
                      ).showSnackBar(

                        const SnackBar(
                          content:
                          Text(
                            "Gagal mengirim",
                          ),
                        ),
                      );
                    }
                  },

                  icon:
                  const Icon(
                    Icons
                        .local_shipping,
                  ),

                  label:
                  const Text(
                    "Konfirmasi Penjemputan",
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget _itemSampah(
      JenisSampah item,
      ){

    final isSelected =
        selectedJenis?.id ==
            item.id;


    return GestureDetector(

      onTap: () {

        setState(() {

          selectedJenis =
              item;

        });
      },

      child: Column(
        mainAxisSize:
        MainAxisSize.min,

        children: [

          Container(
            padding:
            const EdgeInsets
                .all(10),

            decoration:
            BoxDecoration(
              color:
              Colors.green[100],

              shape:
              BoxShape.circle,

              border:
              Border.all(

                color:
                isSelected
                    ? Colors.green
                    : Colors
                    .transparent,

                width: 3,
              ),
            ),

            child:
            Image.asset(

              getIcon(
                item.kodeIcon,
              ),

              width: 40,
              height: 40,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            item.nama,

            style:
            const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}