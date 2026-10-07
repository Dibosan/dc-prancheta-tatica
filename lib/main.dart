import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:html' as html;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const PranchetaTaticaApp());
}

class PranchetaTaticaApp extends StatelessWidget {
  const PranchetaTaticaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prancheta Tática By Dibosan',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const PranchetaTatica(),
    );
  }
}

class PranchetaTatica extends StatefulWidget {
  const PranchetaTatica({super.key});

  @override
  State<PranchetaTatica> createState() => _PranchetaTaticaState();
}

class _PranchetaTaticaState extends State<PranchetaTatica> {
  final GlobalKey _mesaKey = GlobalKey();
  Future<void> _salvarTatica() async {
    try {
      final boundary =
      _mesaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        return;
      }

      final bytes = byteData.buffer.asUint8List();

      final blob = html.Blob(
        [bytes],
        'image/png',
      );

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(
        href: url,
      )
        ..setAttribute(
          'download',
          'Dibosan_prancheta_tatica.png',
        )
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Erro ao salvar tática: $e');
    }
  }

  // Cada item representa uma linha/seta completa.
  final List<TracoTatico> _tracos = [];

  // Ponto inicial e final do traço atual.
  Offset? _inicioAtual;
  Offset? _fimAtual;
// Pontos do desenho livre atual.
  final List<Offset> _pontosAtuais = [];

// Modo de desenho: false = seta / true = livre.
  bool _modoLivre = false;

  // Cor selecionada para os novos traços.
  Color _corAtual = Colors.yellow;

  // Paleta de cores.
  final List<Color> _cores = [
    Colors.yellow,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.white,
  ];

  void _iniciarTraco(DragStartDetails details) {
    setState(() {
      _inicioAtual = details.localPosition;
      _fimAtual = details.localPosition;

      if (_modoLivre) {
        _pontosAtuais.clear();
        _pontosAtuais.add(details.localPosition);
      }
    });
  }

  void _continuarTraco(DragUpdateDetails detalhes) {
    setState(() {
      _fimAtual = detalhes.localPosition;

      if (_modoLivre) {
        _pontosAtuais.add(detalhes.localPosition);
      }
    });
  }

  void _finalizarTraco(DragEndDetails detalhes) {
    if (_inicioAtual == null || _fimAtual == null) {
      return;
    }

    setState(() {
      if (_modoLivre) {
        if (_pontosAtuais.length >= 2) {
          _tracos.add(
            TracoTatico(
              inicio: _inicioAtual!,
              fim: _fimAtual!,
              cor: _corAtual,
              pontos: List.from(_pontosAtuais),
              livre: true,
            ),
          );
        }
      } else {
        _tracos.add(
          TracoTatico(
            inicio: _inicioAtual!,
            fim: _fimAtual!,
            cor: _corAtual,
          ),
        );
      }

      _inicioAtual = null;
      _fimAtual = null;
      _pontosAtuais.clear();
    });
  }



  void _desfazer() {
    if (_tracos.isEmpty) {
      return;
    }

    setState(() {
      _tracos.removeLast();
    });
  }

  void _limpar() {
    setState(() {
      _tracos.clear();
      _inicioAtual = null;
      _fimAtual = null;
    });
  }

  void _selecionarCor(Color cor) {
    setState(() {
      _corAtual = cor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE85A24),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE85A24),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PRANCHETA TÁTICA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'BY DIBOSAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
      Expanded(
      child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 400,
          height: 714,
          child: RepaintBoundary(
          key: _mesaKey,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23498F),
                    border: Border.all(
                      color: Colors.white,
                      width: 5,
                    ),
                  ),

                  child: GestureDetector(
                    onPanStart: _iniciarTraco,
                    onPanUpdate: _continuarTraco,
                    onPanEnd: _finalizarTraco,

                    child: CustomPaint(
                      painter: MesaPainter(
                        tracos: _tracos,
                        inicioAtual: _inicioAtual,
                        fimAtual: _fimAtual,
                        corAtual: _corAtual,
                        modoLivre: _modoLivre,
                        pontosAtuais: _pontosAtuais,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
      ),

          // ================================
          // SELEÇÃO DE CORES
          // ================================
          Padding(
            padding: const EdgeInsets.only(
              top: 2,
              bottom: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _cores.map((cor) {
                final bool selecionada = _corAtual == cor;

                return GestureDetector(
                  onTap: () => _selecionarCor(cor),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cor,
                      border: Border.all(
                        color: selecionada
                            ? Colors.black
                            : Colors.white,
                        width: selecionada ? 5 : 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

// ==================================================
// MODO DE DESENHO
// ==================================================

          Padding(
            padding: const EdgeInsets.only(
              top: 2,
              bottom: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modoLivre = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Seta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _modoLivre ? Colors.white : Colors.deepPurple,
                    foregroundColor:
                    _modoLivre ? Colors.deepPurple : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modoLivre = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Livre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _modoLivre ? Colors.deepPurple : Colors.white,
                    foregroundColor:
                    _modoLivre ? Colors.white : Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================================
          // BOTÕES
          // ================================
          Padding(
            padding: const EdgeInsets.only(
              left: 6,
              right: 6,
              bottom: 2,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _desfazer,
                      icon: const Icon(Icons.undo),
                      label: const Text('Desfazer'),
                    ),

                    const SizedBox(width: 15),

                    ElevatedButton.icon(
                      onPressed: _limpar,
                      icon: const Icon(Icons.delete),
                      label: const Text('Limpar'),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                ElevatedButton.icon(
                  onPressed: _salvarTatica,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODELO DE CADA TRAÇO
// ============================================================

class TracoTatico {
  final Offset inicio;
  final Offset fim;
  final Color cor;

  // Usado pelo modo de desenho livre.
  final List<Offset> pontos;
  final bool livre;

  TracoTatico({
    required this.inicio,
    required this.fim,
    required this.cor,
    this.pontos = const [],
    this.livre = false,
  });
}

// ============================================================
// DESENHO DA MESA E DAS SETAS
// ============================================================

class MesaPainter extends CustomPainter {
  final List<TracoTatico> tracos;
  final Offset? inicioAtual;
  final Offset? fimAtual;
  final Color corAtual;
  final bool modoLivre;
  final List<Offset> pontosAtuais;

  MesaPainter({
    required this.tracos,
    required this.inicioAtual,
    required this.fimAtual,
    required this.corAtual,
    required this.modoLivre,
    required this.pontosAtuais,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ==========================================
    // LINHAS DA MESA
    // ==========================================

    // ==========================================
    // MESA OFICIAL
    // ==========================================

    // Linha central longitudinal da mesa.
    final linhaMesa = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linhaMesa,
    );

    // ==========================================
    // REDE
    // ==========================================

    final centroY = size.height / 2;
    const alturaRede = 18.0;

    final topoRede = centroY - alturaRede / 2;
    final baseRede = centroY + alturaRede / 2;

    // Sombra da rede.
    final sombraRede = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        0,
        topoRede + 4,
        size.width,
        baseRede + 4,
      ),
      sombraRede,
    );

    // Corpo escuro da rede.
    final rede = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        0,
        topoRede,
        size.width,
        baseRede,
      ),
      rede,
    );

    // Malha da rede - linhas verticais.
    final malhaVertical = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1;

    const espacamentoVertical = 8.0;

    for (
    double x = 0;
    x <= size.width;
    x += espacamentoVertical
    ) {
      canvas.drawLine(
        Offset(x, topoRede),
        Offset(x, baseRede),
        malhaVertical,
      );
    }

    // Malha da rede - linhas horizontais.
    final malhaHorizontal = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1;

    const espacamentoHorizontal = 5.0;

    for (
    double y = topoRede;
    y <= baseRede;
    y += espacamentoHorizontal
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        malhaHorizontal,
      );
    }

    // Faixas brancas superior e inferior da rede.
    final faixaRede = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(0, topoRede),
      Offset(size.width, topoRede),
      faixaRede,
    );

    canvas.drawLine(
      Offset(0, baseRede),
      Offset(size.width, baseRede),
      faixaRede,
    );

    // ==========================================
    // TRAÇOS JÁ FINALIZADOS
    // ==========================================

    for (final traco in tracos) {
      if (traco.livre) {
        _desenharLivre(
          canvas,
          traco.pontos,
          traco.cor,
        );
      } else {
        _desenharSeta(
          canvas,
          traco.inicio,
          traco.fim,
          traco.cor,
        );
      }
    }

    // ==========================================
    // TRAÇO ATUAL
    // ==========================================

    if (modoLivre) {
      if (pontosAtuais.length >= 2) {
        _desenharLivre(
          canvas,
          pontosAtuais,
          corAtual,
        );
      }
    } else {
      if (inicioAtual != null && fimAtual != null) {
        _desenharSeta(
          canvas,
          inicioAtual!,
          fimAtual!,
          corAtual,
        );
      }
    }
  }

  void _desenharLivre(
      Canvas canvas,
      List<Offset> pontos,
      Color cor,
      ) {
    if (pontos.length < 2) {
      return;
    }

    final linha = Paint()
      ..color = cor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < pontos.length - 1; i++) {
      canvas.drawLine(
        pontos[i],
        pontos[i + 1],
        linha,
      );
    }
  }

  void _desenharSeta(
      Canvas canvas,
      Offset inicio,
      Offset fim,
      Color cor,
      ) {
    final linha = Paint()
      ..color = cor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Linha reta.
    canvas.drawLine(
      inicio,
      fim,
      linha,
    );

    // ==========================================
    // CABEÇA DA SETA
    // ==========================================

    final dx = fim.dx - inicio.dx;
    final dy = fim.dy - inicio.dy;

    final distancia = math.sqrt(
      dx * dx + dy * dy,
    );

    // Evita problemas quando o toque praticamente
    // não saiu do lugar.
    if (distancia < 5) {
      return;
    }

    final angulo = math.atan2(dy, dx);

    const tamanhoSeta = 24.0;
    const aberturaSeta = math.pi / 6;

    final ponto1 = Offset(
      fim.dx - tamanhoSeta * math.cos(angulo - aberturaSeta),
      fim.dy - tamanhoSeta * math.sin(angulo - aberturaSeta),
    );

    final ponto2 = Offset(
      fim.dx - tamanhoSeta * math.cos(angulo + aberturaSeta),
      fim.dy - tamanhoSeta * math.sin(angulo + aberturaSeta),
    );

    canvas.drawLine(
      fim,
      ponto1,
      linha,
    );

    canvas.drawLine(
      fim,
      ponto2,
      linha,
    );
  }

  @override
  bool shouldRepaint(covariant MesaPainter oldDelegate) {
    return true;
  }
}