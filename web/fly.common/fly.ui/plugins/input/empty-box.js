﻿!function () { var $ = fly; $.ui.EmptyBox = $.Class({ baseCss: "f", emptyCss: "", constructor: function (_) { var A = this; if ($.isString(_) || $.isDom(_)) _ = { input: _ }; $.extend(this, _); this.input = $(this.input); this.input[0].getValue = this.value.bind(this); this.input[0].emptyBox = this; this.form = $(this.input[0].form); this.cssBox = $(this.cssBox || this.input.attr("cssBox") || this.input); this.emptyValue = this.emptyValue || this.input.attr("emptyValue") || ""; this.createLabel(); if (this.input[0].title == "") this.input[0].title = this.emptyValue; this.emptyCss = this.emptyCss || this.baseCss + "-empty"; if (A.input[0] == $.activeElement()) this.doFocus(); else this.checkEmpty(); this.initEvents(); this.form.submit(this.doSubmit, this) }, getId: function () { var $ = this.input[0].id; if (!$) $ = this.input[0].id = "f" + Math.random().toString().substr(3); return $ }, createLabel: function () { if (this.emptyValue && this.input[0].type == "password" && $.browser.isIE && $.browser.ieVersion < 9) { this.label = '<label for="{0}">{1}</label>'.format(this.getId(), this.emptyValue); this.input.before(this.label) } }, doSubmit: function () { if (this.input[0].value == this.emptyValue) this.input[0].value = ""; setTimeout(this.checkEmpty.bind(this)) }, setInputType: function ($, A) { try { $.type = A } catch (_) { } }, doFocus: function () { if (this.input[0].value == this.emptyValue) this.input[0].value = ""; this.cssBox.removeClass(this.emptyCss); if (this.input[0].isPassword === true) this.setInputType(this.input[0], "password"); this.actived = true }, doBlur: function () { this.actived = false; this.checkEmpty() }, checkEmpty: function () { var _ = this.input[0].value; if ($.activeElement() == this.input[0] || (_ && _ != this.emptyValue)) { this.cssBox.removeClass(this.emptyCss); if (this.input[0].isPassword === true) this.setInputType(this.input[0], "password") } else { this.cssBox.addClass(this.emptyCss); if (!this.label) this.input[0].value = this.emptyValue; if (this.input[0].type == "password") { this.setInputType(this.input[0], "text"); this.input[0].isPassword = true } return true } }, value: function ($) { if (arguments.length) { this.input[0].value = $; this.checkEmpty() } else { $ = this.input[0].value; if ($ == this.emptyValue) $ = "" } return $ }, initEvents: function () { this.input.keydown(this.doFocus, this).focus(this.doFocus, this).blur(this.doBlur, this).change(this.checkEmpty, this) } }); $.ui.EmptyBox.instances = []; $.Event.eventAble($.ui.EmptyBox); $.ui.EmptyBox.applyAll = function (_) { $(_).each("o=>new $.ui.EmptyBox({input:$(o)})") } } ()