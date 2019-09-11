// Generated by CoffeeScript 1.12.2
(function() {
  var $, Base, DomView, Enum, EnumAttributeEditView, List, Varying, blankEntry, find, from, isArray, isPrimitive, ref, ref1, stringifier, template, uniqueId, withBlank,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ref = require('janus'), Varying = ref.Varying, DomView = ref.DomView, from = ref.from, template = ref.template, find = ref.find, Base = ref.Base, List = ref.List;

  Enum = require('janus').attribute.Enum;

  ref1 = require('janus').util, isArray = ref1.isArray, isPrimitive = ref1.isPrimitive, uniqueId = ref1.uniqueId;

  stringifier = require('../util/util').stringifier;

  $ = require('./dollar');

  blankEntry = new List([null]);

  withBlank = function(l) {
    return blankEntry.concat(l);
  };

  EnumAttributeEditView = (function(superClass) {
    extend(EnumAttributeEditView, superClass);

    function EnumAttributeEditView() {
      return EnumAttributeEditView.__super__.constructor.apply(this, arguments);
    }

    EnumAttributeEditView.prototype.dom = function() {
      return $('<select/>');
    };

    EnumAttributeEditView.prototype._initialize = function() {
      return this._stringifier = stringifier(this);
    };

    EnumAttributeEditView.prototype._updateVal = function(select) {
      var binding, i, len, ref2, selected;
      if (this._textBindings == null) {
        return;
      }
      selected = this.subject.getValue_();
      ref2 = this._textBindings.list;
      for (i = 0, len = ref2.length; i < len; i++) {
        binding = ref2[i];
        if (!(binding.item === selected)) {
          continue;
        }
        select.val(binding.optionId);
        return;
      }
    };

    EnumAttributeEditView.prototype._optionsList = function() {
      if (this.subject.nullable === true) {
        return this.subject.values().map(withBlank);
      } else {
        return this.subject.values();
      }
    };

    EnumAttributeEditView.prototype._render = function() {
      var select;
      select = this.dom();
      this._optionsList().react((function(_this) {
        return function(list) {
          var binding, bindings, i, idx, len, ref2, results;
          _this._removeAll(select);
          _this._textBindings = bindings = list.map(function(item) {
            return _this._generateTextBinding(item);
          });
          _this._hookBindings(select, bindings);
          ref2 = bindings.list;
          results = [];
          for (idx = i = 0, len = ref2.length; i < len; idx = ++i) {
            binding = ref2[idx];
            results.push(_this._add(select, binding.dom, idx));
          }
          return results;
        };
      })(this));
      return select;
    };

    EnumAttributeEditView.prototype._attach = function(select) {
      var initial;
      initial = true;
      this._optionsList().react((function(_this) {
        return function(list) {
          var bindings, options;
          if (initial !== true) {
            _this._removeAll(select);
          }
          options = select.children().get();
          _this._textBindings = bindings = list.map(function(item) {
            var option, rawOption, textBinding;
            if (initial === true) {
              rawOption = options.shift();
              option = $(rawOption);
              textBinding = _this._stringifier.flatMap(function(f) {
                return f(item);
              }).react(false, function(text) {
                return option.text(text);
              });
              textBinding.item = item;
              textBinding.optionId = rawOption.value;
              textBinding.dom = option;
              return textBinding;
            } else {
              return _this._generateTextBinding(item);
            }
          });
          return _this._hookBindings(select, bindings);
        };
      })(this));
      initial = false;
    };

    EnumAttributeEditView.prototype._generateTextBinding = function(item) {
      var id, option, textBinding;
      option = $('<option/>');
      textBinding = this._stringifier.flatMap(function(f) {
        return f(item);
      }).react(function(text) {
        return option.text(text);
      });
      id = this._generateId(item);
      option.attr('value', id);
      textBinding.item = item;
      textBinding.optionId = id;
      textBinding.dom = option;
      return textBinding;
    };

    EnumAttributeEditView.prototype._hookBindings = function(select, bindings) {
      this.listenTo(bindings, 'added', (function(_this) {
        return function(binding, idx) {
          return _this._add(select, binding.dom, idx);
        };
      })(this));
      this.listenTo(bindings, 'removed', (function(_this) {
        return function(binding) {
          binding.dom.remove();
          return binding.stop();
        };
      })(this));
    };

    EnumAttributeEditView.prototype._generateId = function(value) {
      if (value == null) {
        return toString.call(value);
      } else if (isPrimitive(value)) {
        return value.toString();
      } else {
        return uniqueId().toString();
      }
    };

    EnumAttributeEditView.prototype._removeAll = function(select) {
      var _, binding, ref2;
      if (this._textBindings != null) {
        ref2 = this._textBindings.list;
        for (_ in ref2) {
          binding = ref2[_];
          binding.stop();
        }
        this.unlistenTo(this._textBindings);
        this._textBindings.destroy();
      }
      select.empty();
    };

    EnumAttributeEditView.prototype._add = function(dom, option, idx) {
      var children;
      children = dom.children();
      if (idx === 0) {
        dom.prepend(option);
      } else if (idx === children.length) {
        dom.append(option);
      } else {
        children.eq(idx).before(option);
      }
      this._updateVal(dom);
    };

    EnumAttributeEditView.prototype._wireEvents = function() {
      var select, subject, update;
      select = this.artifact();
      subject = this.subject;
      subject.getValue().react((function(_this) {
        return function() {
          return _this._updateVal(select);
        };
      })(this));
      update = (function(_this) {
        return function() {
          var binding, i, len, ref2, selectedId, selectedOption;
          selectedOption = select.children(':selected');
          if (selectedOption.length === 0) {
            selectedOption = select.children(':first');
          }
          selectedId = selectedOption.attr('value');
          ref2 = _this._textBindings.list;
          for (i = 0, len = ref2.length; i < len; i++) {
            binding = ref2[i];
            if (!(binding.optionId === selectedId)) {
              continue;
            }
            subject.setValue(binding.item);
            return;
          }
        };
      })(this);
      select.on('change input', update);
      update();
    };

    return EnumAttributeEditView;

  })(DomView);

  module.exports = {
    EnumAttributeEditView: EnumAttributeEditView,
    registerWith: function(library) {
      return library.register(Enum, EnumAttributeEditView, {
        context: 'edit'
      });
    }
  };

}).call(this);