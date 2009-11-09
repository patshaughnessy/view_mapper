function add_child(element, child_name, new_child) {
  $(child_name + '_children').insert({
    bottom: new_child.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function remove_child(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) {
    hidden_field.value = '1';
  }
  $(element).up(".child").hide();
}
