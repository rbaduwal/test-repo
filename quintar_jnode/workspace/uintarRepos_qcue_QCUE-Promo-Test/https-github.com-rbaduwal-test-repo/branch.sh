rm -rvf Q.reality_SDK
git clone git@github.com:quintar-dev/Q.reality_SDK.git
cd Q.reality_SDK && git branch -r | awk '{print $1}' ORS=\'\\n\' > ../branch
cut -d '/' -f 2,3 ../branch > ../file
sed -e "s/'//g" ../file > ../branches
default="QRP-2070-release"
pwd
sed -i -e "/$default/d" ../branches
#sed -i -e "1i $default" ../branches
#awk '!/$default/' ../branches
sed -i -e '1s/^/'"$default"'\n/' ../branches
