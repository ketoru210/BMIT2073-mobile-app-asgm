import 'package:flutter/material.dart';

import '../data/feedback_repository.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';

class FeedbackPage extends StatefulWidget {
	const FeedbackPage({super.key});

	@override
	State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
	final _formKey = GlobalKey<FormState>();
	final _subjectController = TextEditingController();
	final _messageController = TextEditingController();
	final _repository = FeedbackRepository();

	String _category = 'feedback';
	bool _submitting = false;

	@override
	void dispose() {
		_subjectController.dispose();
		_messageController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;

		setState(() => _submitting = true);

		try {
			await _repository.submit(
				category: _category,
				subject: _subjectController.text,
				message: _messageController.text,
			);

			if (!mounted) return;

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Thank you. Your report was submitted.')),
			);
			Navigator.of(context).pop();
		} catch (error) {
			if (!mounted) return;

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Unable to submit your report. Please try again.'),
				),
			);
		} finally {
			if (mounted) setState(() => _submitting = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Palette.ground,
			body: SafeArea(
				child: Form(
					key: _formKey,
					child: ListView(
						padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
						children: [
							Row(
								children: [
									BackChevron(
										onTap: () => Navigator.of(context).maybePop(),
									),
									const SizedBox(width: 6),
									const Text(
										'FEEDBACK / REPORT ISSUE',
										style: TextStyle(
											fontSize: 17,
											fontWeight: FontWeight.w700,
											color: Palette.ink,
										),
									),
								],
							),
							const SizedBox(height: 26),
							const Text(
								'Tell us what happened or how we can improve the app.',
								style: TextStyle(fontSize: 12, color: Palette.muted),
							),
							const SizedBox(height: 18),
							AppCard(
								padding: const EdgeInsets.all(18),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										const Text(
											'TYPE',
											style: TextStyle(
												fontSize: 11,
												fontWeight: FontWeight.w700,
												color: Palette.muted,
											),
										),
										const SizedBox(height: 8),
										DropdownButtonFormField<String>(
											initialValue: _category,
											decoration: _inputDecoration('Choose a type'),
											items: const [
												DropdownMenuItem(
													value: 'feedback',
													child: Text('Feedback'),
												),
												DropdownMenuItem(
													value: 'bug',
													child: Text('Bug'),
												),
												DropdownMenuItem(
													value: 'report',
													child: Text('Report an issue'),
												),
											],
											onChanged: _submitting
													? null
													: (value) {
															if (value != null) {
																setState(() => _category = value);
															}
														},
										),
										const SizedBox(height: 18),
										const Text(
											'SUBJECT',
											style: TextStyle(
												fontSize: 11,
												fontWeight: FontWeight.w700,
												color: Palette.muted,
											),
										),
										const SizedBox(height: 8),
										TextFormField(
											controller: _subjectController,
											enabled: !_submitting,
											maxLength: 150,
											textInputAction: TextInputAction.next,
											decoration: _inputDecoration('Short description'),
											validator: (value) {
												if (value == null || value.trim().isEmpty) {
													return 'Please enter a subject.';
												}
												return null;
											},
										),
										const SizedBox(height: 8),
										const Text(
											'MESSAGE',
											style: TextStyle(
												fontSize: 11,
												fontWeight: FontWeight.w700,
												color: Palette.muted,
											),
										),
										const SizedBox(height: 8),
										TextFormField(
											controller: _messageController,
											enabled: !_submitting,
											maxLength: 5000,
											minLines: 6,
											maxLines: 8,
											textInputAction: TextInputAction.newline,
											decoration: _inputDecoration('Describe your feedback'),
											validator: (value) {
												if (value == null || value.trim().isEmpty) {
													return 'Please enter a message.';
												}
												return null;
											},
										),
										const SizedBox(height: 8),
										SizedBox(
											width: double.infinity,
											height: 48,
											child: FilledButton.icon(
												onPressed: _submitting ? null : _submit,
												icon: _submitting
														? const SizedBox(
																width: 18,
																height: 18,
																child: CircularProgressIndicator(
																	strokeWidth: 2,
																	color: Colors.white,
																),
															)
														: const Icon(Icons.send_outlined, size: 18),
												label: Text(_submitting ? 'Submitting...' : 'Submit'),
												style: FilledButton.styleFrom(
													backgroundColor: Palette.primary,
													foregroundColor: Colors.white,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(12),
													),
												),
											),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}

	InputDecoration _inputDecoration(String hint) {
		return InputDecoration(
			hintText: hint,
			hintStyle: const TextStyle(color: Palette.faint, fontSize: 13),
			filled: true,
			fillColor: Palette.ground,
			contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
			border: OutlineInputBorder(
				borderRadius: BorderRadius.circular(10),
				borderSide: const BorderSide(color: Palette.border),
			),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(10),
				borderSide: const BorderSide(color: Palette.border),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(10),
				borderSide: const BorderSide(color: Palette.primary, width: 1.5),
			),
		);
	}
}
