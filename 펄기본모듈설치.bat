@ECHO OFF
PATH C:\strawberry\perl\site\bin;C:\strawberry\perl\bin;C:\strawberry\c\bin;%PATH%
SET TERM=dumb
CMD /c cpan Path::Tiny
CMD /c cpan Moose
CMD /c cpan Types::Standard
CMD /c cpan Try::Tiny
CMD /c cpan Types::Path::Tiny
pause