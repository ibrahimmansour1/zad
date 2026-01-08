import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';
import 'package:zad_aldaia/features/articles/logic/articles_cubit.dart';
import 'package:zad_aldaia/features/articles/ui/widgets/article_item.dart';

class ArticlesScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final String? section;
  final String? language;

  const ArticlesScreen(
      {super.key,
      required this.categoryId,
      required this.title,
      this.section,
      this.language});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late ArticlesCubit cubit = getIt<ArticlesCubit>();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    cubit.loadArticles({'category_id': widget.categoryId});
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              backgroundColor: MyColors.primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: MyTextStyle.headingMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: MyColors.primaryColor,
        elevation: 0,
        actions: [
          const AdminModeIndicator(),
          const AdminModeQuickToggle(),
          GlobalHomeButton(),
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed(
              MyRoutes.searchScreen,
            ),
          ),
          if (Supabase.instance.client.auth.currentUser != null)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => Navigator.of(context).pushNamed(
                MyRoutes.addArticleScreen,
                arguments: {
                  "category_id": widget.categoryId,
                  "category_title": widget.title,
                },
              ),
            ),
        ],
      ),
      body: BlocProvider(
        create: (context) => cubit,
        child: BlocBuilder<ArticlesCubit, ArticlesState>(
          builder: (context, state) {
            if (state is LoadingState) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(MyColors.primaryColor),
                ),
              );
            }

            if (state is ErrorState) {
              return Center(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is ListLoadedState) {
              if (state.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No articles found',
                        style: MyTextStyle.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (Supabase.instance.client.auth.currentUser != null)
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed(
                            MyRoutes.addArticleScreen,
                            arguments: {
                              "category_id": widget.categoryId,
                              "category_title": widget.title,
                            },
                          ),
                          child: const Text(
                            'Create First Article',
                            style: TextStyle(
                              color: Color(0xFF005A32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF005A32),
                onRefresh: () async {
                  await cubit.loadArticles({'category_id': widget.categoryId});
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final article = state.items[index];
                    final isFirst = index == 0;
                    final isLast = index == state.items.length - 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ArticleItem(
                        article: article,
                        isFirst: isFirst,
                        isLast: isLast,
                        onPressed: (article) => Navigator.of(context).pushNamed(
                          MyRoutes.items,
                          arguments: {
                            "id": article.id,
                            "title": article.title,
                          },
                        ),
                        onDeleted: (article) {
                          cubit
                              .loadArticles({'category_id': widget.categoryId});
                        },
                        onMoveUp: isFirst
                            ? null
                            : (article) async {
                                await cubit.moveArticleUp(
                                    article.id, widget.categoryId);
                              },
                        onMoveDown: isLast
                            ? null
                            : (article) async {
                                await cubit.moveArticleDown(
                                    article.id, widget.categoryId);
                              },
                      ),
                    );
                  },
                ),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }
}
