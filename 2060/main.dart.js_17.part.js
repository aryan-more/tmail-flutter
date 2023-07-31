// Generated by dart2js (NullSafetyMode.sound, trust primitives, omit checks, lax runtime type, csp, deferred-serialization, intern-composite-values), the Dart to JavaScript compiler version: 2.19.2.
self.$__dart_deferred_initializers__ = self.$__dart_deferred_initializers__ || Object.create(null);
$__dart_deferred_initializers__.current = function(hunkHelpers, init, holdersList, $) {
  var B = {
    ContactView$() {
      var t1, t2;
      $.$get$Get();
      t1 = $.GetInstance__getInstance;
      if (t1 == null)
        t1 = $.GetInstance__getInstance = C.C_GetInstance;
      t1 = t1.find$1$1$tag(0, null, type$.ResponsiveUtils);
      t2 = $.GetInstance__getInstance;
      if (t2 == null)
        t2 = $.GetInstance__getInstance = C.C_GetInstance;
      return new B.ContactView(t1, t2.find$1$1$tag(0, null, type$.ImagePaths), null);
    },
    ContactView: function ContactView(t0, t1, t2) {
      this._contact_view$_responsiveUtils = t0;
      this._contact_view$_imagePaths = t1;
      this.key = t2;
    },
    ContactView_build_closure1: function ContactView_build_closure1(t0) {
      this.context = t0;
    },
    ContactView_build_closure: function ContactView_build_closure(t0, t1) {
      this.$this = t0;
      this.context = t1;
    },
    ContactView_build_closure0: function ContactView_build_closure0(t0) {
      this.$this = t0;
    },
    ContactView_build__closure0: function ContactView_build__closure0(t0) {
      this.$this = t0;
    },
    ContactView_build__closure: function ContactView_build__closure(t0) {
      this.$this = t0;
    },
    ContactView_build___closure: function ContactView_build___closure(t0, t1) {
      this.$this = t0;
      this.context = t1;
    },
    AppBarContactWidget: function AppBarContactWidget(t0, t1, t2) {
      this._app_bar_contact_widget$_imagePaths = t0;
      this.onCloseContactView = t1;
      this.key = t2;
    },
    ContactUtils_getPaddingAppBar(context, responsiveUtils) {
      return C.EdgeInsets_16_0_16_0;
    },
    ContactUtils_getPaddingSearchInputForm(context, responsiveUtils) {
      return F.EdgeInsets_16_10_16_10;
    },
    ContactUtils_getPaddingSearchResultList(context, responsiveUtils) {
      return F.EdgeInsets_16_10_16_10;
    },
    ContactUtils_getPaddingDividerSearchResultList(context, responsiveUtils) {
      return C.EdgeInsets_16_0_16_0;
    },
    ContactUtils_supportAppBarTopBorder(context, responsiveUtils) {
      return false;
    },
    ContactUtils_getRadiusBorderAppBarTop(context, responsiveUtils) {
      if (B.ContactUtils_supportAppBarTopBorder(context, responsiveUtils))
        return 16;
      else
        return 0;
    }
  },
  C, A, G, H, D, E, J, I, F;
  B = hunkHelpers.updateHolder(holdersList[7], B);
  C = holdersList[2];
  A = holdersList[0];
  G = holdersList[18];
  H = holdersList[21];
  D = holdersList[16];
  E = holdersList[22];
  J = holdersList[1];
  I = holdersList[11];
  F = holdersList[23];
  B.ContactView.prototype = {
    build$1(context) {
      var t8, t9, t10, t11, t12, t13, t14, t15, t16, _this = this, _null = null,
        t1 = _this._contact_view$_responsiveUtils,
        t2 = B.ContactUtils_supportAppBarTopBorder(context, t1),
        t3 = B.ContactUtils_getRadiusBorderAppBarTop(context, t1),
        t4 = B.ContactUtils_getRadiusBorderAppBarTop(context, t1),
        t5 = B.ContactUtils_getRadiusBorderAppBarTop(context, t1),
        t6 = B.ContactUtils_getRadiusBorderAppBarTop(context, t1),
        t7 = B.ContactUtils_getPaddingAppBar(context, t1);
      $.$get$Get();
      t8 = $.GetInstance__getInstance;
      if (t8 == null)
        t8 = $.GetInstance__getInstance = C.C_GetInstance;
      t7 = A.Container$(_null, new B.AppBarContactWidget(t8.find$1$1$tag(0, _null, type$.ImagePaths), new B.ContactView_build_closure(_this, context), _null), C.Clip_0, C.Color_4294967295, _null, _null, _null, 52, _null, _null, t7, _null, _null, _null);
      t8 = $.$get$GetWidget__cache();
      A.Expando__checkType(_this);
      t8 = t8._jsWeakMap;
      t9 = A._instanceType(_this)._eval$1("GetWidget.S");
      t10 = t9._as(t8.get(_this)).searchQuery;
      t10 = t10.get$value(t10);
      A.Expando__checkType(_this);
      t11 = t9._as(t8.get(_this)).textInputSearchFocus;
      A.Expando__checkType(_this);
      t12 = t9._as(t8.get(_this)).textInputSearchController;
      t1 = B.ContactUtils_getPaddingSearchInputForm(context, t1);
      t13 = A.SvgPicture$asset("assets/images/ic_clear_text_search.svg", _null, C.BoxFit_0, 18, _null, 18);
      A.Localizations_of(context, C.Type_AppLocalizations_swi, type$.AppLocalizations).toString;
      t14 = A.Intl__message("Enter name or email", _null, "hintSearchInputContact", _null, _null);
      A.Expando__checkType(_this);
      t15 = t9._as(t8.get(_this)).get$clearAllTextInputSearchForm();
      A.Expando__checkType(_this);
      t16 = t9._as(t8.get(_this)).get$onTextSearchChange();
      A.Expando__checkType(_this);
      return A.Scaffold$(_null, C.Color_1627389952, A.GestureDetector$(_null, A.SafeArea$(false, A.Container$(_null, A.ClipRRect$(new A.BorderRadius(new A.Radius(t5, t5), new A.Radius(t6, t6), C.Radius_0_0, C.Radius_0_0), A.SafeArea$(true, A.Container$(_null, A.Column$(A._setArrayType([t7, G.Divider_6xV, A.SearchAppBarWidget$(H.BoxDecoration_Oi20, false, true, 44, t14, t13, _this._contact_view$_imagePaths, t1, t15, t9._as(t8.get(_this)).get$onSearchTextAction(), t16, C.EdgeInsets_0_0_0_0, t11, t12, t10), A.Expanded$(new A.Obx(new B.ContactView_build_closure0(_this), _null), 1)], type$.JSArray_Widget), C.CrossAxisAlignment_2, _null, C.MainAxisAlignment_0, C.MainAxisSize_1, C.VerticalDirection_1), C.Clip_0, C.Color_4294967295, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null), true, C.EdgeInsets_0_0_0_0, true, true), C.Clip_2), C.Clip_0, _null, _null, new A.BoxDecoration(C.Color_4294967295, _null, _null, new A.BorderRadius(new A.Radius(t3, t3), new A.Radius(t4, t4), C.Radius_0_0, C.Radius_0_0), _null, _null, _null, C.BoxShape_0), _null, _null, _null, _null, _null, _null, _null, _null), false, C.EdgeInsets_0_0_0_0, false, t2), C.DragStartBehavior_1, false, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null, new B.ContactView_build_closure1(context), _null, _null, _null, _null, _null, _null, _null), _null, _null, true, _null, _null, _null);
    },
    _contact_view$_toSuggestionEmailAddress$2(item, addedEmailAddresses) {
      if (C.JSArray_methods.contains$1(addedEmailAddresses, item))
        return new D.SuggestionEmailAddress(item, E.SuggestionEmailState_1);
      else
        return new D.SuggestionEmailAddress(item, E.SuggestionEmailState_0);
    }
  };
  B.AppBarContactWidget.prototype = {
    build$1(context) {
      var _null = null,
        t1 = A.SvgPicture$asset("assets/images/ic_close_composer.svg", A.ColorNullableExtension_asFilter(C.Color_4286680217), C.BoxFit_0, 24, _null, 24),
        t2 = type$.AppLocalizations;
      A.Localizations_of(context, C.Type_AppLocalizations_swi, t2).toString;
      t1 = A.Positioned$(_null, A.buildIconWeb(_null, _null, t1, C.EdgeInsets_5_5_5_5, 25, 25, this.onCloseContactView, 15, A.Intl__message("Close", _null, "close", _null, _null)), _null, _null, 0, _null, _null, _null);
      A.Localizations_of(context, C.Type_AppLocalizations_swi, t2).toString;
      return new A.Stack(C.Alignment_0_0, _null, C.StackFit_0, C.Clip_1, A._setArrayType([t1, A.Center$(A.Text$(A.Intl__message("Contact", _null, "contact", _null, _null), _null, _null, _null, _null, _null, C.TextStyle_oHY, _null, _null, _null), _null, _null, _null)], type$.JSArray_Widget), _null);
    }
  };
  var typesOffset = hunkHelpers.updateTypes(["ContactSuggestionBoxItem(BuildContext,int)"]);
  B.ContactView_build_closure1.prototype = {
    call$0() {
      return A.FocusScope_of(this.context).unfocus$0();
    },
    $signature: 0
  };
  B.ContactView_build_closure.prototype = {
    call$0() {
      var t1 = this.$this,
        t2 = $.$get$GetWidget__cache();
      A.Expando__checkType(t1);
      A._instanceType(t1)._eval$1("GetWidget.S")._as(t2._jsWeakMap.get(t1)).clearAllTextInputSearchForm$0();
      A.FocusScope_of(this.context).unfocus$0();
      A.GetNavigation_back($.$get$Get(), null);
      return null;
    },
    $signature: 0
  };
  B.ContactView_build_closure0.prototype = {
    call$0() {
      var t3, t4, _null = null,
        t1 = this.$this,
        t2 = $.$get$GetWidget__cache();
      A.Expando__checkType(t1);
      t2 = t2._jsWeakMap;
      t3 = A._instanceType(t1)._eval$1("GetWidget.S");
      t4 = t3._as(t2.get(t1)).listContactSearched;
      if (!t4.get$isEmpty(t4)) {
        A.Expando__checkType(t1);
        t2 = t3._as(t2.get(t1)).listContactSearched;
        return A.Container$(_null, A.ListView$separated(_null, new B.ContactView_build__closure(t1), J.get$length$asx(t2.get$value(t2)), C.ScrollViewKeyboardDismissBehavior_0, _null, _null, false, C.Axis_1, new B.ContactView_build__closure0(t1), false), C.Clip_0, C.Color_4294967295, _null, _null, _null, _null, _null, _null, _null, _null, _null, _null);
      } else
        return C.SizedBox_0_0_null_null;
    },
    $signature: 3
  };
  B.ContactView_build__closure0.prototype = {
    call$2(context, index) {
      return new A.Padding(B.ContactUtils_getPaddingDividerSearchResultList(context, this.$this._contact_view$_responsiveUtils), C.Divider_I9g, null);
    },
    $signature: 395
  };
  B.ContactView_build__closure.prototype = {
    call$2(context, index) {
      var t3, t4, emailAddress,
        t1 = this.$this,
        t2 = $.$get$GetWidget__cache();
      A.Expando__checkType(t1);
      t2 = t2._jsWeakMap;
      t3 = A._instanceType(t1)._eval$1("GetWidget.S");
      t4 = t3._as(t2.get(t1)).listContactSearched;
      emailAddress = J.$index$asx(t4.get$value(t4), index);
      A.Expando__checkType(t1);
      t4 = type$.JSArray_EmailAddress;
      if (t3._as(t2.get(t1)).contactSelected != null) {
        A.Expando__checkType(t1);
        t2 = t3._as(t2.get(t1)).contactSelected;
        t2.toString;
        t4 = A._setArrayType([t2], t4);
        t2 = t4;
      } else
        t2 = A._setArrayType([], t4);
      return new I.ContactSuggestionBoxItem(t1._contact_view$_toSuggestionEmailAddress$2(emailAddress, t2), new B.ContactView_build___closure(t1, context), B.ContactUtils_getPaddingSearchResultList(context, t1._contact_view$_responsiveUtils), null, null);
    },
    $signature: typesOffset + 0
  };
  B.ContactView_build___closure.prototype = {
    call$1(contact) {
      var t1 = this.$this,
        t2 = $.$get$GetWidget__cache();
      A.Expando__checkType(t1);
      A._instanceType(t1)._eval$1("GetWidget.S")._as(t2._jsWeakMap.get(t1));
      A.FocusScope_of(this.context).unfocus$0();
      A.GetNavigation_back($.$get$Get(), contact);
      return null;
    },
    $signature: 87
  };
  (function inheritance() {
    var _inherit = hunkHelpers.inherit,
      _inheritMany = hunkHelpers.inheritMany;
    _inherit(B.ContactView, A.GetWidget);
    _inheritMany(A.Closure0Args, [B.ContactView_build_closure1, B.ContactView_build_closure, B.ContactView_build_closure0]);
    _inheritMany(A.Closure2Args, [B.ContactView_build__closure0, B.ContactView_build__closure]);
    _inherit(B.ContactView_build___closure, A.Closure);
    _inherit(B.AppBarContactWidget, A.StatelessWidget);
  })();
  A._Universe_addRules(init.typeUniverse, JSON.parse('{"ContactView":{"GetWidget":["ContactController"],"Widget":[],"DiagnosticableTree":[],"GetWidget.S":"ContactController"},"AppBarContactWidget":{"StatelessWidget":[],"Widget":[],"DiagnosticableTree":[]}}'));
  var type$ = {
    AppLocalizations: A.findType("AppLocalizations"),
    ImagePaths: A.findType("ImagePaths0"),
    JSArray_EmailAddress: A.findType("JSArray<EmailAddress>"),
    JSArray_Widget: A.findType("JSArray<Widget>"),
    ResponsiveUtils: A.findType("ResponsiveUtils0")
  };
};

$__dart_deferred_initializers__["N8z3jhy7vhGdK23ol9V3fgKZ8s8="] = $__dart_deferred_initializers__.current
