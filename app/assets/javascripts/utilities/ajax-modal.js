class AjaxModal {
    loadModal(url, title) {
        this.createModel(title);
        var that = this;

        $.get(url, data => {})
            .done(content => {
                const response = $("<div>").html(content);
                that.dialog.find("#modal-title").html(response.find("#title").html());
                that.dialog.find("#modal-body").html(response.find("#modal").html());
            })
            .fail(err => {
                if (401 == err.status) {
                    that.dialog.find(".modal-body").html(
                        `<div class='col text-center p-5'> <h2>${err.responseText}</h2>
              <p><a href="/users/sign_in?return_to=${location.pathname}" class="btn btn-primary">Login</a></p></div>`
                    );
                }
            });
    }

    createModel(title) {
        if ($("#ajax-modal").length > 0) $("#ajax-modal").remove();

        let modal = `
        <div class="modal" tabindex="-1" role="dialog" id="ajax-modal">
  <div class='modal-dialog' role="document">
    <div class="modal-content">
      <div class="modal-header">
       <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title" id="modal-title">${title || 'Loading'}</h4>
  </div>
      
      <div id="modal-body">
      <div class="modal-body" id="modal-body">
        <p class="text-center"><i class="fa fa-spinner fal fa-spinner fa-spin fa-2x my-3"></i> Loading</p>
      </div>
      <div class="modal-footer" id="modal-footer"></div>
      </div>
    </div>
  </div>
</div>
`;
        this.dialog = $(modal);
        this.dialog.appendTo("body");
        this.dialog.modal({backdrop: "static"});
    }
}

window.AjaxModal = AjaxModal;
