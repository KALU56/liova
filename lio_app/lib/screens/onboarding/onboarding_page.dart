import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onCompleted,
    required this.onGoToSignIn,
  });

  final Future<void> Function() onCompleted;
  final Future<void> Function() onGoToSignIn;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Read Ingredient Labels Faster',
      description:
          'Take a clear photo of skincare labels and let Liova extract the text for you.',
      icon: Icons.document_scanner_rounded,
      accentColor: Color(0xFF2563EB),
    ),
    _OnboardingSlide(
      title: 'AI Risk Analysis',
      description:
          'Get low, medium, or high risk levels for each ingredient with clear explanations.',
      icon: Icons.psychology_alt_rounded,
      accentColor: Color(0xFF0F766E),
    ),
    _OnboardingSlide(
      title: 'Track Reactions Over Time',
      description:
          'Save scans, add skin notes, and build safer skincare decisions every week.',
      icon: Icons.history_rounded,
      accentColor: Color(0xFFEA580C),
    ),
  ];

  int _currentPage = 0;
  bool _isBusy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToSignIn() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    await widget.onGoToSignIn();
    if (!mounted) return;
    setState(() => _isBusy = false);
  }

  Future<void> _handleNextOrComplete() async {
    if (_isBusy) return;

    if (_currentPage < _slides.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _isBusy = true);
    await widget.onCompleted();
    if (!mounted) return;
    setState(() => _isBusy = false);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/signin');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F4FF), Color(0xFFF8FBF2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _isBusy ? null : _handleBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Text(
                      'Liova',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isBusy ? null : _goToSignIn,
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _SlideCard(slide: _slides[index]);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFB5C4D6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _handleNextOrComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(isLastPage ? 'Create Account' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [slide.accentColor.withValues(alpha: 0.28), Colors.white],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.spa_rounded,
                size: 120,
                color: Color(0x220F766E),
              ),
              Icon(slide.icon, size: 74, color: slide.accentColor),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 29,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
}
