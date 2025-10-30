NestedScrollView(
                  // slivers: [
                  //   SliverAppBar(
                  //     expandedHeight: 200.0,
                  //     floating: false,
                  //     pinned: true,
                  //     flexibleSpace: FlexibleSpaceBar(
                  //         // titlePadding: EdgeInsets.zero,

                  //         centerTitle: false,
                  //         title: const Text("Collapsing Toolbar",
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 16.0,
                  //             )),
                  //         background: Image.network(
                  //           "https://images.pexels.com/photos/396547/pexels-photo-396547.jpeg?auto=compress&cs=tinysrgb&h=350",
                  //           fit: BoxFit.cover,
                  //         )),
                  //   ),
                  //   SliverList(
                  //     delegate: SliverChildBuilderDelegate(
                  //       (_, int index) {
                  //         return ListTile(
                  //           leading: Container(
                  //               padding: EdgeInsets.all(8),
                  //               width: 100,
                  //               child: Placeholder()),
                  //           title: Text('Place ${index + 1}', textScaleFactor: 2),
                  //         );
                  //       },
                  //       childCount: 20,
                  //     ),
                  //   ),
                  // ],
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        scrolledUnderElevation: 0,
                        expandedHeight: 200.0,
                        floating: false,
                        pinned: true,
                        flexibleSpace:
                            LayoutBuilder(builder: (context, constraints) {
                          // Get the current height of the SliverAppBar during scrolling
                          final appBarHeight = constraints.biggest.height;

                          // Calculate dynamic padding based on height (smooth transition)
                          final minHeight = _toolbarHeight;
                          final maxHeight = _maxCollapsingHeight;

                          final double t = (appBarHeight - minHeight) /
                              (maxHeight - minHeight);
                          final double dynamicPadding =
                              (20 + (70 - 20) * (1 - t));
                          final double safePadding =
                              dynamicPadding >= 20 ? dynamicPadding : 20;

                          return FlexibleSpaceBar(
                            titlePadding:
                                EdgeInsets.only(left: safePadding, bottom: 16),
                            centerTitle: false,
                            title: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(foodDetail.name,
                                    maxLines: 4,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.w600)),
                                Visibility(
                                  visible: (minHeight + 20) < appBarHeight,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${(foodDetail.foodPortions[_selectedPortionIndex].gramWeight * quantities[_selectedQuantityIndex]).toStringDigitFraction()} g - ${foodDetail.macronutrientsBreakdown.calories.toStringDigitFraction()} Cal",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            foodDetail.isFavorite =
                                                !foodDetail.isFavorite;
                                          });
                                          context
                                              .read<favCubit.FavouriteCubit>()
                                              .addRemoveFavouriteFoods(
                                                  foodDetail.id,
                                                  isFavorite:
                                                      foodDetail.isFavorite);
                                          context.showMessage(
                                            foodDetail.isFavorite
                                                ? 'Added to favorite food'
                                                : 'Removed from favorite food',
                                            type: ToastificationType.info,
                                          );
                                        },
                                        child: foodDetail.isFavorite
                                            ? Icon(
                                                Icons.favorite,
                                                size: 18,
                                                color: context
                                                    .read<ThemeCubit>()
                                                    .appTheme
                                                    .accentColor,
                                              )
                                            : Icon(
                                                Icons.favorite_border,
                                                size: 18,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.black38,
                                                      blurRadius: 10)
                                                ],
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            background: AppNetworkImageView(
                                placeholderIconColor:
                                    context.getAppTheme().textColor,
                                imageUrl: foodDetail.image,
                                placeHolder: Image.asset(
                                  'assets/images/img_default_food_image.webp',
                                  fit: BoxFit.cover,
                                )),
                          );
                          // background: Image.network(
                          //   "https://images.pexels.com/photos/396547/pexels-photo-396547.jpeg?auto=compress&cs=tinysrgb&h=350",
                          //   fit: BoxFit.cover,
                          // ));
                        }),
                      ),
                    ];
                  },
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text("Pick the quantity", style: titleStyle),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: CupertinoPicker(
                                  itemExtent: 40,
                                  scrollController: FixedExtentScrollController(
                                      initialItem: _selectedQuantityIndex),
                                  selectionOverlay: Container(
                                    decoration: const BoxDecoration(
                                      border: Border.symmetric(
                                          horizontal: BorderSide(
                                              color: Color(0xFF404040))),
                                    ),
                                  ),
                                  onSelectedItemChanged: (value) {
                                    _selectedQuantityIndex = value;
                                    context
                                        .read<FoodDetailsCubit>()
                                        .updateNutrients(
                                            portion: foodDetail.foodPortions[
                                                _selectedPortionIndex],
                                            quantity: quantities[value]);
                                  },
                                  children: quantities
                                      .map((e) => Center(
                                          child: Text(e.trimTrailingZero(),
                                              style: const TextStyle(
                                                  fontSize: 14))))
                                      .toList()),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: CupertinoPicker(
                                  itemExtent: 40,
                                  scrollController: FixedExtentScrollController(
                                      initialItem: _selectedPortionIndex),
                                  selectionOverlay: Container(
                                    decoration: const BoxDecoration(
                                      border: Border.symmetric(
                                          horizontal: BorderSide(
                                              color: Color(0xFF404040))),
                                    ),
                                  ),
                                  onSelectedItemChanged: (value) {
                                    _selectedPortionIndex = value;
                                    context
                                        .read<FoodDetailsCubit>()
                                        .updateNutrients(
                                            portion:
                                                foodDetail.foodPortions[value],
                                            quantity: quantities[
                                                _selectedQuantityIndex]);
                                  },
                                  children: foodDetail.foodPortions
                                      .map((e) => Center(
                                              child: Text(
                                            e.modifier,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          )))
                                      .toList()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      MacronutrientsBreakdownWidget(
                          titleTextStyle: titleStyle,
                          macronutrientsBreakdown:
                              foodDetail.macronutrientsBreakdown),
                      const SizedBox(height: 20),
                      MicronutrientsBreakdownWidget(
                          titleTextStyle: titleStyle,
                          microNutrients: foodDetail.microNutrients),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
