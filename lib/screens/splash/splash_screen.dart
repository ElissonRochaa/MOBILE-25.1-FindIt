import 'dart:async';
import 'package:flutter/material.dart';
import 'package:find_it/service/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _elementAnimController;
  late Animation<double> _elementFadeAnimation;
  late Animation<double> _elementScaleAnimation;

  late final AnimationController _lottieController;

  bool _showText1 = false;
  bool _showLottie = false;
  bool _showText2 = false;
  bool _showLogoPng = false;

  final Duration _initialDelay = const Duration(milliseconds: 500);
  final Duration _text1DisplayDuration = const Duration(seconds: 2);
  final Duration _lottieDisplayDuration = const Duration(seconds: 3);
  final Duration _text2DisplayDuration = const Duration(seconds: 2);
  final Duration _logoPngDisplayDuration = const Duration(seconds: 2);
  final Duration _elementTransitionDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _elementAnimController = AnimationController(
      vsync: this,
      duration: _elementTransitionDuration,
    );
    _elementFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _elementAnimController, curve: Curves.easeInOut),
    );
    _elementScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _elementAnimController, curve: Curves.easeOutBack),
    );
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(_initialDelay);
    if (!mounted) return;
    setState(() => _showText1 = true);
    _elementAnimController.forward();

    await Future.delayed(_text1DisplayDuration + _elementTransitionDuration);
    if (!mounted) return;
    await _elementAnimController.reverse();
    setState(() => _showText1 = false);

    if (!mounted) return;
    setState(() => _showLottie = true);
    _elementAnimController.forward();

    await Future.delayed(_lottieDisplayDuration + _elementTransitionDuration);
    if (!mounted) return;
    await _elementAnimController.reverse();
    setState(() => _showLottie = false);
    if (_lottieController.isAnimating) _lottieController.stop();

    if (!mounted) return;
    setState(() => _showText2 = true);
    _elementAnimController.forward();

    await Future.delayed(_text2DisplayDuration + _elementTransitionDuration);
    if (!mounted) return;
    await _elementAnimController.reverse();
    setState(() => _showText2 = false);

    if (!mounted) return;
    setState(() => _showLogoPng = true);
    _elementAnimController.forward();

    await Future.delayed(_logoPngDisplayDuration + _elementTransitionDuration);
    if (!mounted) return;

    _checkLoginAndNavigate();
  }

  // 2. A função de navegação foi atualizada para usar context.go()
  Future<void> _checkLoginAndNavigate() async {
    if (!mounted) return;
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      context.go('/feed');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _elementAnimController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedElement({required bool visible, required Widget child}) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: _elementTransitionDuration,
      child: visible
          ? ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _elementAnimController, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _elementAnimController, curve: Curves.easeIn),
          ),
          child: child,
        ),
      )
          : child,
    );
  }

  Widget _buildAnimatedLottie({required bool visible, required Widget child}) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: _elementTransitionDuration,
      child: visible
          ? ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: _elementAnimController, curve: Curves.easeOutBack),
        ),
        child: child,
      )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_showText1)
                _buildAnimatedElement(
                  visible: _showText1,
                  child: const Text(
                    "Perdeu?",
                    key: ValueKey("text1"),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              if (_showLottie)
                _buildAnimatedLottie(
                  visible: _showLottie,
                  child: Lottie.asset(
                    'assets/lottie/findit.json',
                    key: const ValueKey("lottie"),
                    controller: _lottieController,
                    width: 250,
                    height: 250,
                    onLoaded: (composition) {
                      _lottieController
                        ..duration = composition.duration
                        ..forward().whenComplete(() {});
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Erro Lottie: $error");
                      return const SizedBox(height: 250, child: Center(child: Text('Erro animação', style: TextStyle(color: Colors.red))));
                    },
                  ),
                ),
              if (_showText2)
                _buildAnimatedElement(
                  visible: _showText2,
                  child: const Text(
                    "A gente acha!",
                    key: ValueKey("text2"),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              if (_showLogoPng)
                _buildAnimatedElement(
                  visible: _showLogoPng,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Image.asset(
                      "images/logo.png",
                      key: const ValueKey("logoPng"),
                      width: 350,
                    ),
                  ),
                ),
              if (!_showText1 && !_showLottie && !_showText2 && !_showLogoPng && mounted && _elementAnimController.status != AnimationStatus.forward && _elementAnimController.status != AnimationStatus.reverse)
                const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}