import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom; // Tambahkan impor ini
import '../utils/log_manager.dart';

class LogWidget extends StatefulWidget {
  final LogManager logManager;

  const LogWidget({super.key, required this.logManager});

  @override
  LogWidgetState createState() => LogWidgetState();
}

class LogWidgetState extends State<LogWidget> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.logManager.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    widget.logManager.removeListener(_onLogChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onLogChanged() {
    if (mounted) {
      setState(() {
        // Memastikan widget diupdate
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Tambahkan ini untuk AutomaticKeepAliveClientMixin
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Container(
      color: backgroundColor,
      child: AnimatedBuilder(
        animation: widget.logManager,
        builder: (context, child) {
          return ListView.separated(
            controller: _scrollController,
            itemCount: widget.logManager.logs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
            itemBuilder: (context, index) {
              final log = widget.logManager.logs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: RichText(
                  text: TextSpan(
                    children: _parseHtml(log.formattedLogHtml, context),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<TextSpan> _parseHtml(String htmlString, BuildContext context) {
    var document = parse(htmlString);
    var textSpans = <TextSpan>[];

    document.body?.nodes.forEach((node) {
      if (node.nodeType == dom.Node.TEXT_NODE) { // Text node
        textSpans.add(TextSpan(
          text: node.text ?? '', // Pastikan node.text tidak null
          style: TextStyle(
            fontFamily: 'Monospace',
            fontSize: 12,
            color: _getLogColor(node.text ?? '', context), // Pastikan node.text tidak null
          ),
        ));
      } else if (node.nodeType == dom.Node.ELEMENT_NODE) { // Element node
        var element = node as dom.Element;
        textSpans.add(TextSpan(
          text: element.text, // Pastikan element.text tidak null
          style: TextStyle(
            fontFamily: 'Monospace',
            fontSize: 12,
            color: _getLogColor(element.text, context), // Pastikan element.text tidak null
            fontWeight: element.localName == 'b' ? FontWeight.bold : FontWeight.normal,
            fontStyle: element.localName == 'i' ? FontStyle.italic : FontStyle.normal,
          ),
        ));
      }
    });

    return textSpans;
  }

  Color _getLogColor(String message, BuildContext context) {
    if (message.contains('Error') || message.contains('Gagal')) {
      return Colors.red;
    } else if (message.contains('Peringatan')) {
      return Colors.orange;
    } else if (message.contains('Sukses')) {
      return Colors.green;
    } else {
      return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    }
  }
}
