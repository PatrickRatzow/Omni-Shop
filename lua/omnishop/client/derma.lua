local speed = 900;
net.Receive("OmniShop_Menu", function(len)
  local ply = LocalPlayer();
  local ent = net.ReadEntity();
  local scrW, scrH = ScrW(), ScrH();
  local theme = OmniShop.theme;
  local tab = ent.tab or 1;
  local frame = vgui.Create("DFrame");
  local plyLevel = OmniShop.levelSystemTable[OmniShop.levelSystem]["level"].get(ply);
  if (plyLevel == nil) then plyLevel = 1; end
  local rounding = 6;
  
  ent.categories = {};
  if (scrW <= 1366) then
    w = 900;
    if (scrW <= 799) then -- 640x480...
      w = 640;
      rounding = 0;
    end
  else
    w = scrW * 0.5;
  end
  if (scrH <= 766) then
    h = 540;
    if (scrH <= 539) then -- get a decent PC
      h = 480;
    end
  else
    h = scrH * 0.5;
  end

  frame:SetSize(w, h);
  frame:Center();
  frame:DockPadding(0, 0, 0, 0);
  frame:SetTitle("");
  frame:ShowCloseButton(false);
  frame:MakePopup();
  frame.Paint = function(self, w, h)
    draw.RoundedBox(rounding, 0, 0, w, h, theme["Frame"].color);
  end

  local navbar = vgui.Create("DPanel", frame);
  navbar:Dock(TOP);
  navbar.Paint = function(self, w, h)
    draw.RoundedBoxEx(rounding, 0, 0, w, h, theme["Navbar"].color, true, true, false, false);
  end

  for i = 1, table.Count(ent.config) do
    ent.categories[i] = {};
    ent.categories[i].Button = vgui.Create("DButton", navbar);
    ent.categories[i].Panel = vgui.Create("DPanel", frame);

    local btn = ent.categories[i].Button;
    local pnl = ent.categories[i].Panel;

    btn:Dock(LEFT);
    btn.id = i;
    btn:SetFont("Omni_Tab");
    btn:SetText(ent.config[i].catName);
    btn.PerformLayout = function(self, w, h)
      DButton.PerformLayout(self, w, h)
      surface.SetFont("Omni_Tab");
      local tW, tX = surface.GetTextSize(self:GetText());
      self:SetWide(tW + 40);
    end
    btn.h = nil;
    btn.start = 0;
    btn.Paint = function(self, w, h)
      local hover = self:IsHovered();
      if (tab == self.id) then
        if (self.h == nil) then self.h = 2 end
        self.start = 2;
        self:SetTextColor(theme["Colors"].white);
      else
        if (self.h == nil) then self.h = 0; end
        self.start = 0;
        self:SetTextColor(Color(218, 222, 222));
      end

      if (hover) then
        self.h = math.Approach(self.h, h, RealFrameTime() * (speed/2));
      else
        self.h = math.Approach(self.h, btn.start, RealFrameTime() * (speed/2));
      end
      if (self.h >= h - 4 && self.id == 1) then
        draw.RoundedBoxEx(rounding, 0, h - self.h, w, self.h, theme["Colors"].blue, true, false, false, false);
      else
        draw.RoundedBox(0, 0, h - self.h, w, self.h, theme["Colors"].blue);
      end
    end
    btn.DoClick = function(self, w, h)
      tab = self.id;
      ent.tab = tab;
      for i,v in pairs (ent.categories) do
        if (tab == i) then
          v.Panel:SetVisible(true);
        else
          v.Panel:SetVisible(false);
        end
      end
    end

    pnl:Dock(FILL);
    pnl.Paint = function() end

    local scroll = vgui.Create("DScrollPanel", pnl);
    scroll:Dock(FILL);
    local vbar = scroll:GetVBar();
    vbar.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, theme["Navbar"].color);
    end
    vbar.btnGrip.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, theme["Frame"].color);
    end
    vbar.btnUp.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, theme["Frame"].color);
    end
    vbar.btnDown.Paint = function(self, w, h)
      draw.RoundedBox(0, 0, 0, w, h, theme["Frame"].color);
    end

    local layout = vgui.Create("DListLayout", scroll);
    local texture = Material("gui/gradient_down.vtf");
    local changeColor = false;
    for _,v in pairs(ent.config[i]) do
      if (_ != "catName") then
        local itemPrice = OmniShop.findPrice(ply, v.price, ent.vipGroups);
        local plyIsVIP = OmniShop.isVIP(ent, ply);
        local isVip = v.vip;
        local level = v.level or -1;
        local plyWrongTeam = false;
        if (v.allowedTeams != nil) then
          if (!table.HasValue(v.allowedTeams, ply:Team())) then
            plyWrongTeam = true;
          end
        end

        local panel = vgui.Create("DPanel");
        panel:Dock(FILL);
        panel.id = _;
        panel.color = theme["Rows"].odd;
        if (changeColor) then
          panel.color = theme["Rows"].even;
        end
        changeColor = !changeColor;
        panel.Paint = function(self, w, h)
          draw.RoundedBox(0, 0, 0, w, h, self.color);
        end

        local mdl;
        if (v.model) then
          mdl = vgui.Create("DModelPanel", panel);
          mdl:Dock(LEFT);
          mdl:DockMargin(10, 10, 10, 10);
          mdl:SetModel(v.img);
          mdl.type = "mdl";
          mdl.LayoutEntity = function() end
          local mn, mx = mdl.Entity:GetRenderBounds();
          local size = 0;
          size = math.max(size, math.abs(mn.x) + math.abs(mx.x));
          size = math.max(size, math.abs(mn.y) + math.abs(mx.y));
          size = math.max(size, math.abs(mn.z) + math.abs(mx.z));

          mdl:SetFOV(45);
          mdl:SetCamPos(Vector(size, size, size));
          mdl:SetLookAt((mn + mx) * 0.5);
        else
          mdl = vgui.Create("DPanel", panel);
          mdl:Dock(LEFT);
          mdl.type = "img";
          mdl:DockMargin(20, 15, 20, 15);
          mdl.img = Material(v.img);
          mdl.Paint = function(self, w, h)
            surface.SetMaterial(self.img);
            surface.SetDrawColor(color_white);
            surface.DrawTexturedRect(0, 0, w, h);
          end
        end

        local name = vgui.Create("DLabel", panel);
        name:SetPos(95, 15);
        name:SetFont("Omni_ShopName");
        name:SetTextColor(theme["Colors"].whiteGrey);
        name:SetText(v.name or "no name");
        name:SetContentAlignment(5);
        name:SizeToContents();

        local desc = vgui.Create("DLabel", panel);
        desc:SetPos(95, name:GetTall() + 10);
        desc:SetFont("Omni_ShopDesc");
        desc:SetTextColor(theme["Colors"].whiteGrey);
        desc:SetText(v.desc or "LOREM IPSUM BBY");
        desc:SetContentAlignment(5);
        desc:SizeToContents();

        local buy = vgui.Create("DButton", panel);
        buy:Dock(RIGHT);
        buy:SetText("PURCHASE");
        buy:SetFont("Omni_ShopBuy");
        buy:DockMargin(0, 20, 20, 20);
        local buyColor;
        if (ply:canAfford(itemPrice)) then
          buyColor = theme["Colors"].green;
          if (isVip && !plyIsVIP) then
            buyColor = theme["Colors"].red;
          elseif (level >= 1 && plyLevel < level) then
            buyColor = theme["Colors"].red;
          elseif (plyWrongTeam) then
            buyColor = theme["Colors"].red;
          end
        else
          buyColor = theme["Colors"].red;
        end
        buy:AddGhostEffect(theme["Navbar"].color, buyColor,
        function(self, w, h, col, startCol, hover)
          local color;
          if (hover) then
            color = col;
          else
            color = startCol;
          end

          self:SetTextColor(color);
        end);
        buy.DoClick = function(self)
          net.Start("OmniShop_Purchase");
            net.WriteUInt(i, 5);
            net.WriteUInt(_, 16);
            net.WriteEntity(ent);
          net.SendToServer();
        end

        local price = vgui.Create("DLabel", panel);
        price:Dock(RIGHT);
        price:SetContentAlignment(6);
        price:DockMargin(0, 0, 15, 0);
        price:SetFont("Omni_ShopDollar");
        price:SetText(DarkRP.formatMoney(itemPrice));
        price:SetTextColor(theme["Colors"].whiteGrey);
        price:SizeToContents();

        if (plyWrongTeam) then
          local wrongTeam = vgui.Create("DLabel", panel);
          wrongTeam:Dock(RIGHT);
          wrongTeam:SetText(v.wrongTeamMsg or "Wrong team!");
          wrongTeam:DockMargin(0, 0, 10, 0);
          wrongTeam:SetTextColor(theme["Colors"].red);
          wrongTeam:SetFont("Omni_ShopDollar");
          wrongTeam:SetContentAlignment(6);
          wrongTeam:SizeToContents();
        end

        if (!ply:canAfford(itemPrice)) then
          local cantAfford = vgui.Create("DLabel", panel);
          cantAfford:Dock(RIGHT);
          cantAfford:SetText("Can't afford!");
          cantAfford:DockMargin(0, 0, 10, 0);
          cantAfford:SetTextColor(theme["Colors"].red);
          cantAfford:SetFont("Omni_ShopDollar");
          cantAfford:SetContentAlignment(6);
          cantAfford:SizeToContents();
        end

        if (isVip && !plyIsVIP) then
          local vip = vgui.Create("DLabel", panel);
          vip:Dock(RIGHT);
          vip:SetText("Donator only!");
          vip:DockMargin(0, 0, 10, 0);
          vip:SetFont("Omni_ShopDollar");
          vip:SetTextColor(theme["Colors"].red);
          vip:SetContentAlignment(6);
          vip:SizeToContents();
        end

        if (level >= 1 && (plyLevel < level)) then
          local levelText = vgui.Create("DLabel", panel);
          levelText:Dock(RIGHT);
          levelText:SetText("Level "..level);
          levelText:DockMargin(0, 0, 10, 0);
          levelText:SetFont("Omni_ShopDollar");
          levelText:SetTextColor(theme["Colors"].red);
          levelText:SetContentAlignment(6);
          levelText:SizeToContents();
        end

        panel.PerformLayout = function(self, w, h)
          DPanel.PerformLayout(self, w, h);
          self:SetTall(80);
          if (mdl.type == "mdl") then
            mdl:SetSize(80, 80);
          else
            mdl:SetSize(60, 60);
          end
          buy:SetWide(100);
        end
        layout:Add(panel);
      end
    end
    local gradient = vgui.Create("DPanel", pnl);
    gradient.Paint = function(self, w, h)
      surface.SetMaterial(texture);
      surface.SetDrawColor(0, 0, 0, 120);
      surface.DrawTexturedRect(0, 0, w, h);
    end
    pnl.PerformLayout = function(self, w, h)
      DPanel.PerformLayout(self, w, h);
      layout:SetWide(scroll:GetWide());
      gradient:SetSize(w, 5);
    end

    for i,v in pairs (ent.categories) do
      if (IsValid(v.Panel)) then
        if (i == tab) then
          v.Panel:SetVisible(true);
        else
          v.Panel:SetVisible(false);
        end
      end
    end

  end

  local closeBtn = vgui.Create("DButton", navbar);
  closeBtn:Dock(RIGHT);
  closeBtn:SetText("");
  closeBtn:AddHoverEffect(theme["Navbar"].color, theme["Colors"].blue,
  function(self, w, h, col, startCol, hover)
    draw.NoTexture();
    if (hover) then
      surface.SetDrawColor(col.r, col.g, col.b);
    else
      surface.SetDrawColor(startCol.r, startCol.g, startCol.b);
    end
    surface.DrawTexturedRectRotated(w/2, h/2, 15, 2, 45);
    surface.DrawTexturedRectRotated(w/2, h/2, 15, 2, 135);
  end);
  closeBtn.DoClick = function(self)
    frame:Close();
  end

  frame.PerformLayout = function(self, w, h)
    DFrame.PerformLayout(self, w, h);
    navbar:SetTall(50);
    closeBtn:SetWide(50);
  end
end)
