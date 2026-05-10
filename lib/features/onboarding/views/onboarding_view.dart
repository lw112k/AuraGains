import 'package:auragains/main.dart';
import 'package:flutter/material.dart';
import '../view_models/onboarding_view_model.dart';
import '../models/onboarding_model.dart';

// ==========================================
// 🎨 MASTER THEME VARIABLES
// ==========================================
const Color _bgColor = Color(0xFF121212);
const Color _boxColor = Color(0xFF1E1E1E);
const Color _fieldColor = Color(0xFF2A2A2A);
const Color _accentColor = Color(0xFF00E5FF); // NEON BLUE
const Color _textPrimary = Colors.white;
const Color _textSecondary = Colors.grey;
const Color _buttonText = Colors.black;

class OnboardingView extends StatefulWidget {
  final OnboardingViewModel viewModel;

  const OnboardingView({super.key, required this.viewModel});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  void _nextPage() async {
    if (widget.viewModel.currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 1. Make sure submitOnboarding returns a bool
      final success = await widget.viewModel.submitOnboarding();

      if (mounted) {
        if (success) {
          // 2. Only triggers if the DB update worked
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (Route<dynamic> route) => false,
          );
        } else {
          // 3. Stops them from proceeding with a broken profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to save profile. Please check your connection and try again.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.viewModel, // Listens for state changes
          builder: (context, _) {
            final data = widget.viewModel.data;

            return Column(
              children: [
                const SizedBox(height: 20),
                // Logo & Progress Indicator
                const Text(
                  "AURAGAINS",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: widget.viewModel.currentPage == index ? 24 : 12,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.viewModel.currentPage >= index
                            ? _accentColor
                            : _fieldColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: widget.viewModel.setPage,
                    children: [
                      _buildGenderStep(data),
                      _buildMetricsStep(data),
                      _buildObjectiveStep(data),
                    ],
                  ),
                ),

                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: widget.viewModel.isLoading
                      ? const CircularProgressIndicator(color: _accentColor)
                      : Row(
                          children: [
                            if (widget.viewModel.currentPage > 0) ...[
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(color: _fieldColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(color: _textPrimary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: _nextPage,
                                child: Text(
                                  widget.viewModel.currentPage == 2
                                      ? 'Finish'
                                      : 'Continue',
                                  style: const TextStyle(
                                    color: _buttonText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Gender ---
  Widget _buildGenderStep(OnboardingModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Tell Us About Yourself",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select your gender to personalise your experience",
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _genderCircle("Male", Icons.male, data.gender == "Male"),
              _genderCircle("Female", Icons.female, data.gender == "Female"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderCircle(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.viewModel.updateGender(title),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _boxColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? _accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _accentColor : _textPrimary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? _accentColor : _textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Height & Weight ---
  Widget _buildMetricsStep(OnboardingModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Physical Attributes",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Custom Toggle
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: _boxColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _toggleButton(
                      "CM / KG",
                      data.unitSystem == 'metric',
                      () => widget.viewModel.toggleUnits('metric'),
                    ),
                  ),
                  Expanded(
                    child: _toggleButton(
                      "FT / LBS",
                      data.unitSystem == 'imperial',
                      () => widget.viewModel.toggleUnits('imperial'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 💡 Pass data.age as the initialValue
            _buildInputField("AGE", "25", "YRS", (val) {
              widget.viewModel.updateMetrics(age: int.tryParse(val));
            }, initialValue: data.age?.toString()),

            const SizedBox(height: 16),

            _buildInputField(
              "WEIGHT",
              "70",
              data.unitSystem == 'metric' ? "KG" : "LBS",
              (val) {
                widget.viewModel.updateMetrics(weight: double.tryParse(val));
              },
              initialValue: data.weight?.toString(),
            ),

            const SizedBox(height: 16),

            _buildInputField(
              "HEIGHT",
              "172",
              data.unitSystem == 'metric' ? "CM" : "FT",
              (val) {
                widget.viewModel.updateMetrics(height: double.tryParse(val));
              },
              initialValue: data.height?.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? _buttonText : _textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String placeholder,
    String suffix,
    Function(String) onChanged, {
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                //
                child: TextFormField(
                  initialValue: initialValue, // 💡 3. Give it the saved data!
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: _textSecondary.withOpacity(0.5),
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
              Text(
                suffix,
                style: const TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Workout Objective ---
  Widget _buildObjectiveStep(OnboardingModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Primary Objective",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "What is your main fitness goal?",
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // match "name" column in 'level' table exactly
          _objectiveCard(
            "Lose Weight",
            "Burn calories & shed body fat",
            "⚖️",
            data.objective == "Lose Weight",
          ),
          _objectiveCard(
            "Build Muscle",
            "Increase muscle mass & size",
            "💪",
            data.objective == "Build Muscle",
          ),
          _objectiveCard(
            "Get Stronger",
            "Lift heavier & build raw power",
            "🏋️",
            data.objective == "Get Stronger",
          ),
          _objectiveCard(
            "Boost Endurance",
            "Improve stamina & cardio",
            "🏃",
            data.objective == "Boost Endurance",
          ),
        ],
      ),
    );
  }

  Widget _objectiveCard(
    String title,
    String subtitle,
    String emoji,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => widget.viewModel.updateObjective(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
