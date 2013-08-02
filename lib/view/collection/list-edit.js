(function() {
  var DomView, ListEditItem, ListEditItemTemplate, ListEditView, ListView, Templater, templater, util, _ref, _ref1, _ref2,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  DomView = require('../dom-view').DomView;

  templater = require('../../templater/package');

  Templater = require('../../templater/templater').Templater;

  ListView = require('./list').ListView;

  ListEditView = (function(_super) {
    __extends(ListEditView, _super);

    function ListEditView() {
      _ref = ListEditView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ListEditView.prototype._initialize = function() {
      var _ref1;

      ListEditView.__super__._initialize.call(this);
      this.options.childOpts = util.extendNew(this.options.childOpts, {
        context: this.options.itemContext,
        list: this.subject
      });
      return this.options.itemContext = (_ref1 = this.options.editWrapperContext) != null ? _ref1 : 'edit-wrapper';
    };

    return ListEditView;

  })(ListView);

  ListEditItemTemplate = (function(_super) {
    __extends(ListEditItemTemplate, _super);

    function ListEditItemTemplate() {
      _ref1 = ListEditItemTemplate.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    ListEditItemTemplate.prototype._binding = function() {
      var binding;

      binding = ListEditItemTemplate.__super__._binding.call(this);
      binding.find('.editItem').render(this.options.app).fromSelf().andAux('context').flatMap(function(item, context) {
        return new templater.WithOptions(item, {
          context: context != null ? context : 'edit'
        });
      });
      return binding;
    };

    return ListEditItemTemplate;

  })(Templater);

  ListEditItem = (function(_super) {
    __extends(ListEditItem, _super);

    function ListEditItem() {
      _ref2 = ListEditItem.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    ListEditItem.prototype.templateClass = ListEditItemTemplate;

    ListEditItem.prototype._auxData = function() {
      return {
        context: this.options.context
      };
    };

    ListEditItem.prototype._wireEvents = function() {
      var dom,
        _this = this;

      dom = this.artifact();
      return dom.find('> .editRemove').on('click', function(event) {
        event.preventDefault();
        return _this.options.list.remove(_this.subject);
      });
    };

    return ListEditItem;

  })(DomView);

  util.extend(module.exports, {
    ListEditView: ListEditView,
    ListEditItemTemplate: ListEditItemTemplate,
    ListEditItem: ListEditItem
  });

}).call(this);
