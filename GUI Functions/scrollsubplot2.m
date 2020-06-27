function ax = scrollsubplot2(nR,ind,prnt)

% [left, right, bottom, top] boundaries between figure
B=[50 75 50 50];

% vertical separation between axes
dY=50;

w=prnt.Position(3)-B(1)-B(2);
h=(prnt.Position(4)-B(3)-B(4)-dY*(nR-1))/nR;


axPos=@(ind) [B(1) prnt.Position(4)-B(4)-ind*h-(ind-1)*dY w h];

ax=axes('parent',prnt,'units','pixels','position',axPos(ind));

ax.UserData(1)=[B dY nR ind]

    function resize(specs)
        
    end


=@() set(ax,'Position',axPos(ind));

end
