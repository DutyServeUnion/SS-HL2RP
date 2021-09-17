function DrawOutlinedBox(x, y, w, h, col1, col2)
  surface.SetDrawColor(col1);
  surface.DrawOutlinedRect(x, y, w, h);
  surface.SetDrawColor(col2);
  surface.DrawRect(x, y, w, h);
end
